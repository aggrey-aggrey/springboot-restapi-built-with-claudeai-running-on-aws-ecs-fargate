#!/bin/bash
# scripts/verify-rds-access.sh

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

echo "Checking RDS and Security Group Configuration..."

# Get RDS instance details
INSTANCE_ID="${APP_NAME}-db-${ENV}"
echo "RDS Instance ID: $INSTANCE_ID"

# Get RDS security group ID
SG_ID=$(aws rds describe-db-instances \
    --db-instance-identifier "$INSTANCE_ID" \
    --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
    --output text)

echo "Security Group ID: $SG_ID"

# Get your current IP
CURRENT_IP=$(curl -s ifconfig.me)
echo "Your current IP: $CURRENT_IP"

# Check security group rules
echo -e "\nChecking inbound rules..."
aws ec2 describe-security-groups \
    --group-ids "$SG_ID" \
    --query 'SecurityGroups[0].IpPermissions[?FromPort==`3306`]'

# Check if current IP is allowed
if aws ec2 describe-security-groups \
    --group-ids "$SG_ID" \
    --query "SecurityGroups[0].IpPermissions[?FromPort==\`3306\`].IpRanges[?CidrIp==\`${CURRENT_IP}/32\`].CidrIp" \
    --output text | grep -q "${CURRENT_IP}/32"; then
    echo -e "\n✅ Your IP is allowed in the security group"
else
    echo -e "\n❌ Your IP is NOT allowed in the security group"

    # Add the rule
    echo "Adding your IP to security group..."
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 3306 \
        --cidr "${CURRENT_IP}/32" \
        --description "MySQL access from workstation"
fi

# Check VPC configuration
echo -e "\nChecking VPC configuration..."
VPC_ID=$(aws rds describe-db-instances \
    --db-instance-identifier "$INSTANCE_ID" \
    --query 'DBInstances[0].DBSubnetGroup.VpcId' \
    --output text)

echo "VPC ID: $VPC_ID"

# Check route tables
echo -e "\nChecking route tables..."
aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'RouteTables[*].{RouteTableId:RouteTableId,Routes:Routes}'

# Test connection
echo -e "\nTesting connection..."
DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "$INSTANCE_ID" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)
DB_PORT=3306

echo "Testing TCP connection to $DB_ENDPOINT:$DB_PORT..."
timeout 5 bash -c "</dev/tcp/$DB_ENDPOINT/$DB_PORT" 2>/dev/null && \
    echo "✅ TCP connection successful" || \
    echo "❌ TCP connection failed"

echo -e "\nDiagnostic Information:"
echo "1. Ensure your IP ($CURRENT_IP) is allowed in the security group"
echo "2. Check that the RDS instance is in a public subnet or has proper routing"
echo "3. Verify that the route table has proper routes to the internet gateway"
echo "4. Check that the subnet's network ACL allows port 3306"

# Print connection details for MySQL clients
echo -e "\nConnection Details for MySQL Client:"
echo "Host: $DB_ENDPOINT"
echo "Port: 3306"
echo "Command to test connection:"
echo "mysql -h $DB_ENDPOINT -P 3306 -u \$(terraform output -raw db_username) -p"