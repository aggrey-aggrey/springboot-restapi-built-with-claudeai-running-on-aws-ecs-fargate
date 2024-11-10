#!/bin/bash
# scripts/update-db-security.sh

set -e

# Get the project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

ENV=${1:-dev}
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
    echo "Usage: $0 [dev|prod]"
    exit 1
fi

APP_NAME="author-books-api"

# Get current IP and add /32 for CIDR notation
CURRENT_IP=$(curl -s ifconfig.me)
CURRENT_IP_CIDR="${CURRENT_IP}/32"
echo "Your current IP address: $CURRENT_IP_CIDR"

# Get RDS instance identifier
INSTANCE_ID="${APP_NAME}-db-${ENV}"

# Get security group ID
echo "Getting security group ID from RDS instance..."
SG_ID=$(aws rds describe-db-instances \
    --db-instance-identifier "$INSTANCE_ID" \
    --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
    --output text)

if [ -z "$SG_ID" ] || [ "$SG_ID" = "None" ]; then
    echo "Error: Could not find security group ID"
    exit 1
fi

echo "Found security group ID: $SG_ID"

echo "Current security group rules:"
aws ec2 describe-security-groups \
    --group-ids "$SG_ID" \
    --query 'SecurityGroups[0].IpPermissions[?FromPort==`3306`]'

# Remove existing IP-based rules
echo "Removing existing IP-based rules..."
aws ec2 revoke-security-group-ingress \
    --group-id "$SG_ID" \
    --ip-permissions '[{
        "IpProtocol": "tcp",
        "FromPort": 3306,
        "ToPort": 3306,
        "IpRanges": [{"CidrIp": "'$CURRENT_IP_CIDR'"}]
    }]' 2>/dev/null || true

# Add new rule for current IP
echo "Adding new rule for IP ${CURRENT_IP_CIDR}..."
aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --ip-permissions '[{
        "IpProtocol": "tcp",
        "FromPort": 3306,
        "ToPort": 3306,
        "IpRanges": [{"CidrIp": "'$CURRENT_IP_CIDR'"}]
    }]'

echo "Security group updated successfully!"

# Verify the changes
echo -e "\nVerifying new rules:"
aws ec2 describe-security-groups \
    --group-ids "$SG_ID" \
    --query 'SecurityGroups[0].IpPermissions[?FromPort==`3306`]'

# Test connection
echo -e "\nTesting connection to database..."
DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "$INSTANCE_ID" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

echo "Testing TCP connection to $DB_ENDPOINT:3306..."
timeout 5 bash -c "</dev/tcp/$DB_ENDPOINT/3306" 2>/dev/null && \
    echo "✅ TCP connection successful" || \
    echo "❌ TCP connection failed"