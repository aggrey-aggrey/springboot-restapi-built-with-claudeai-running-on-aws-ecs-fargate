#!/bin/bash
# scripts/init-database.sh

set -e

ENVIRONMENT=$1
MAX_RETRIES=30
RETRY_INTERVAL=10

# Source environment variables if exists
ENV_FILE="../terraform/environments/${ENVIRONMENT}/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

# Get database endpoint from Terraform output
cd ../terraform
DB_ENDPOINT=$(terraform output -raw rds_endpoint)
DB_HOST=$(echo $DB_ENDPOINT | cut -d: -f1)
DB_PORT=$(echo $DB_ENDPOINT | cut -d: -f2)
DB_NAME=$(terraform output -raw db_name)
cd ..

echo "Waiting for database to be ready..."
for i in $(seq 1 $MAX_RETRIES); do
    if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; then
        echo "Database is ready!"
        break
    fi

    if [ $i -eq $MAX_RETRIES ]; then
        echo "Database did not become ready in time"
        exit 1
    fi

    echo "Attempt $i of $MAX_RETRIES: Database not ready yet, waiting $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
done

# Execute schema script
echo "Creating database schema..."
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_NAME" < spring-boot-api/src/main/resources/db/schema.sql

# Execute data script only in development environment
if [ "$ENVIRONMENT" = "dev" ]; then
    echo "Inserting sample data..."
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_NAME" < spring-boot-api/src/main/resources/db/data.sql
fi

echo "Database initialization completed successfully!"