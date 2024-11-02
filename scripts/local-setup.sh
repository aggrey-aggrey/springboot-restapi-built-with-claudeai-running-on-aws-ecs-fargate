#!/bin/bash
# scripts/local-setup.sh

set -e

# Default local database configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=author-books-db
DB_USERNAME=dev_user
DB_PASSWORD=dev_password
MYSQL_ROOT_PASSWORD=root

echo "Setting up local development environment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Stop and remove existing MySQL container if it exists
if docker ps -a | grep -q "local-mysql"; then
    echo "Stopping and removing existing MySQL container..."
    docker stop local-mysql || true
    docker rm local-mysql || true
fi

# Start MySQL container
echo "Starting MySQL container..."
docker run --name local-mysql \
    -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
    -e MYSQL_DATABASE=$DB_NAME \
    -e MYSQL_USER=$DB_USERNAME \
    -e MYSQL_PASSWORD=$DB_PASSWORD \
    -p $DB_PORT:3306 \
    -d mysql:8.0 \
    --character-set-server=utf8mb4 \
    --collation-server=utf8mb4_unicode_ci

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
for i in {1..30}; do
    if docker exec local-mysql mysqladmin ping -h localhost -u root -p$MYSQL_ROOT_PASSWORD --silent; then
        echo "MySQL is ready!"
        break
    fi
    echo "Waiting for MySQL to be ready... ($i/30)"
    sleep 2
done

# Initialize database with schema and data
echo "Initializing database..."
sleep 5  # Give MySQL a little more time to be fully ready

# Execute schema script
echo "Creating database schema..."
docker exec -i local-mysql mysql -u root -p$MYSQL_ROOT_PASSWORD $DB_NAME < spring-boot-api/src/main/resources/db/schema.sql

# Execute data script
echo "Inserting sample data..."
docker exec -i local-mysql mysql -u root -p$MYSQL_ROOT_PASSWORD $DB_NAME < spring-boot-api/src/main/resources/db/data.sql

echo "Local development environment is ready!"
echo "Database connection details:"
echo "Host: $DB_HOST"
echo "Port: $DB_PORT"
echo "Database: $DB_NAME"
echo "Username: $DB_USERNAME"
echo "Password: $DB_PASSWORD"