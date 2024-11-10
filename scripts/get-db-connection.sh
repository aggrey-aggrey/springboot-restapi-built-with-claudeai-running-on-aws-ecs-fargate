#!/bin/bash
# scripts/get-db-connection.sh

set -e

# Get the project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Check if environment is provided
ENV=${1:-dev}
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
    echo "Usage: $0 [dev|prod]"
    exit 1
fi

# Navigate to terraform directory
cd "$PROJECT_ROOT/terraform"

# Get connection details
echo "Getting database connection details..."
DB_ENDPOINT=$(terraform output -raw rds_endpoint)
DB_HOST=$(echo $DB_ENDPOINT | cut -d: -f1)
DB_PORT=$(echo $DB_ENDPOINT | cut -d: -f2)
DB_NAME=$(terraform output -raw db_name)
DB_USERNAME=$(terraform output -raw db_username)
DB_PASSWORD=$(terraform output -raw db_password)

echo "=== Database Connection Details ==="
echo "Hostname: $DB_HOST"
echo "Port: $DB_PORT"
echo "Database: $DB_NAME"
echo "Username: $DB_USERNAME"
echo "Password: $DB_PASSWORD"
echo "================================="
echo
echo "MySQL Workbench Connection Steps:"
echo "1. Open MySQL Workbench"
echo "2. Click the '+' icon next to 'MySQL Connections'"
echo "3. Enter connection details:"
echo "   - Connection Name: Author Books API ($ENV)"
echo "   - Hostname: $DB_HOST"
echo "   - Port: $DB_PORT"
echo "   - Username: $DB_USERNAME"
echo "4. Click 'Test Connection' to verify"
echo "5. Save and connect using the password provided above"