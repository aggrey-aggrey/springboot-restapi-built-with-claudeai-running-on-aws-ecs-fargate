#!/bin/bash
# scripts/generate-secrets.sh

# Check if environment is provided
ENV=${1:-dev}
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
    echo "Usage: $0 [dev|prod]"
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "Error: AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

# Get the project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
SECRETS_FILE="$PROJECT_ROOT/terraform/environments/$ENV/secrets.tfvars"

# Create directories if they don't exist
mkdir -p "$PROJECT_ROOT/terraform/environments/$ENV"

# Generate random password (Windows compatible version)
generate_password() {
    openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-16
}

# Set RDS configurations based on environment
if [ "$ENV" = "prod" ]; then
    INSTANCE_CLASS="db.t3.small"
    ALLOCATED_STORAGE="50"
    MAX_ALLOCATED_STORAGE="200"
    BACKUP_RETENTION="30"
else
    INSTANCE_CLASS="db.t3.micro"
    ALLOCATED_STORAGE="20"
    MAX_ALLOCATED_STORAGE="100"
    BACKUP_RETENTION="7"
fi

# Create secrets file
cat > "$SECRETS_FILE" << EOF
# Database Credentials
db_username = "${ENV}_user"
db_password = "$(generate_password)"

# RDS Configuration
db_instance_class = "${INSTANCE_CLASS}"
db_allocated_storage = ${ALLOCATED_STORAGE}
db_max_allocated_storage = ${MAX_ALLOCATED_STORAGE}
db_backup_retention_period = ${BACKUP_RETENTION}
EOF

# Set file permissions (might not work fully on Windows)
chmod 600 "$SECRETS_FILE" 2>/dev/null || true

echo "Generated secrets file: $SECRETS_FILE"
echo "⚠️  WARNING: Keep this file secure and never commit it to version control!"

# Display the generated configuration
echo ""
echo "Generated configuration:"
echo "------------------------"
cat "$SECRETS_FILE"

# Display AWS CLI information
echo ""
echo "AWS CLI Configuration:"
echo "------------------------"
aws sts get-caller-identity