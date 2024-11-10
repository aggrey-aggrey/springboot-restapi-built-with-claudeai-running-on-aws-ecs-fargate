#!/bin/bash
# scripts/test-db-connection.sh

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

APP_NAME="author-books-api"

# Verify VPC configuration first
echo "Verifying VPC configuration..."
./scripts/verify-vpc.sh "$ENV"

# Get database information
echo "Getting database information..."
cd "$PROJECT_ROOT/terraform"
DB_ENDPOINT=$(terraform output -raw rds_endpoint)
DB_HOST=$(echo $DB_ENDPOINT | cut -d: -f1)
DB_PORT=$(echo $DB_ENDPOINT | cut -d: -f2)
DB_NAME=$(terraform output -raw db_name)
DB_USERNAME=$(terraform output -raw db_username)
DB_PASSWORD=$(terraform output -raw db_password)

echo "Testing database connection..."
echo "Host: $DB_HOST"
echo "Port: $DB_PORT"
echo "Database: $DB_NAME"
echo "Username: $DB_USERNAME"

# Test TCP connection
echo "Testing TCP connection to $DB_HOST:$DB_PORT..."
if timeout 5 bash -c "</dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; then
    echo "✅ TCP connection successful"
else
    echo "❌ TCP connection failed"
fi

# Test MySQL connection
echo "Testing MySQL connection..."
if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" \
    -e "SELECT VERSION();" 2>/dev/null; then
    echo "✅ MySQL connection successful"
else
    echo "❌ MySQL connection failed"
fi

# Check instance status
echo "Checking instance status..."
aws rds describe-db-instances \
    --db-instance-identifier "${APP_NAME}-db-${ENV}" \
    --query 'DBInstances[0].{Status:DBInstanceStatus,Endpoint:Endpoint.Address}'

# Get security group information
SG_ID=$(aws rds describe-db-instances \
    --db-instance-identifier "${APP_NAME}-db-${ENV}" \
    --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
    --output text)

echo -e "\nSecurity Group Rules:"
aws ec2 describe-security-groups \
    --group-ids "$SG_ID" \
    --query 'SecurityGroups[0].IpPermissions'

echo -e "\nConnection Troubleshooting:"
echo "1. Verify your IP is in the security group"
echo "2. Check that the RDS instance is in the correct subnet"
echo "3. Verify route tables and NAT Gateway"
echo "4. Test connection using MySQL client"