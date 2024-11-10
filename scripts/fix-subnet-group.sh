#!/bin/bash
# scripts/fix-subnet-group.sh

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
SUBNET_GROUP_NAME="${APP_NAME}-${ENV}"

echo "Checking DB subnet group..."
if aws rds describe-db-subnet-groups --db-subnet-group-name "$SUBNET_GROUP_NAME" >/dev/null 2>&1; then
    echo "DB subnet group exists. Deleting it..."
    aws rds delete-db-subnet-group --db-subnet-group-name "$SUBNET_GROUP_NAME"
    echo "Waiting for deletion..."
    sleep 10
fi

echo "DB subnet group fixed. You can now run Terraform apply again."