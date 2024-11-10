#!/bin/bash
# scripts/simple-db-init.sh

set -e

ENV=${1:-dev}
APP_NAME="author-books-api"

# Get database endpoint and credentials
DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "${APP_NAME}-db-${ENV}" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

echo "Database endpoint: $DB_ENDPOINT"
echo "Testing connection..."

# Try to connect and initialize
mysql -h "$DB_ENDPOINT" \
      -u admin \
      -p"your-password" \
      -e "SELECT 1;" && \
echo "Connection successful!" || echo "Connection failed!"