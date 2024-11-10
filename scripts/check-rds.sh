#!/bin/bash
# scripts/check-rds.sh

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

# Application name
APP_NAME="author-books-api"

echo "Checking RDS instance status..."

# Get RDS instance identifier
INSTANCE_ID="${APP_NAME}-db-${ENV}"
SUBNET_GROUP_NAME="${APP_NAME}-${ENV}"

# Check RDS instance status
echo "RDS Instance Details:"
aws rds describe-db-instances \
    --db-instance-identifier "$INSTANCE_ID" \
    --query 'DBInstances[0].{Status:DBInstanceStatus,Endpoint:Endpoint.Address,Port:Endpoint.Port,SecurityGroups:VpcSecurityGroups[*].VpcSecurityGroupId,SubnetGroup:DBSubnetGroup.DBSubnetGroupName}'

# Get VPC ID
VPC_ID=$(aws rds describe-db-instances \
    --db-instance-identifier "$INSTANCE_ID" \
    --query 'DBInstances[0].DBSubnetGroup.VpcId' \
    --output text)

echo -e "\nVPC Details:"
echo "VPC ID: $VPC_ID"

# Get security group rules
echo -e "\nChecking Security Group rules..."
SG_ID=$(aws rds describe-db-instances \
    --db-instance-identifier "$INSTANCE_ID" \
    --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
    --output text)

echo "Security Group Rules for $SG_ID:"
aws ec2 describe-security-groups \
    --group-ids "$SG_ID" \
    --query 'SecurityGroups[0].IpPermissions'

# Check subnet group with more detailed output
echo -e "\nChecking DB Subnet Group..."
aws rds describe-db-subnet-groups \
    --db-subnet-group-name "$SUBNET_GROUP_NAME" \
    --output json

# Get subnet details
echo -e "\nSubnet Details:"
SUBNET_IDS=$(aws rds describe-db-subnet-groups \
    --db-subnet-group-name "$SUBNET_GROUP_NAME" \
    --query 'DBSubnetGroups[0].Subnets[*].SubnetId' \
    --output text)

for subnet in $SUBNET_IDS; do
    echo -e "\nDetails for Subnet: $subnet"
    aws ec2 describe-subnets \
        --subnet-ids "$subnet" \
        --query 'Subnets[0].{CIDR:CidrBlock,AZ:AvailabilityZone,State:State,RouteTable:Tags[?Key==`Name`].Value|[0]}'

    # Get route table
    ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
        --filters "Name=association.subnet-id,Values=$subnet" \
        --query 'RouteTables[0].RouteTableId' \
        --output text)

    echo "Route Table ($ROUTE_TABLE_ID) routes:"
    aws ec2 describe-route-tables \
        --route-table-ids "$ROUTE_TABLE_ID" \
        --query 'RouteTables[0].Routes'
done

# Check public accessibility
echo -e "\nChecking Public Accessibility:"
PUBLICLY_ACCESSIBLE=$(aws rds describe-db-instances \
    --db-instance-identifier "$INSTANCE_ID" \
    --query 'DBInstances[0].PubliclyAccessible' \
    --output text)
echo "Publicly Accessible: $PUBLICLY_ACCESSIBLE"

# Get connection information
echo -e "\nConnectivity Information:"
DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "$INSTANCE_ID" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)
DB_PORT=$(aws rds describe-db-instances \
    --db-instance-identifier "$INSTANCE_ID" \
    --query 'DBInstances[0].Endpoint.Port' \
    --output text)

echo "Database Connection Details:"
echo "Host: $DB_ENDPOINT"
echo "Port: $DB_PORT"

# Test connectivity
echo -e "\nTesting Connectivity:"
if command -v mysql &> /dev/null; then
    echo "Testing TCP connection..."
    timeout 5 bash -c "</dev/tcp/$DB_ENDPOINT/$DB_PORT" 2>/dev/null && \
        echo "✓ TCP connection successful" || \
        echo "✗ TCP connection failed"

    echo -e "\nTesting MySQL connection..."
    # Get credentials from Terraform
    cd "$PROJECT_ROOT/terraform"
    DB_USERNAME=$(terraform output -raw db_username 2>/dev/null || echo "")
    DB_PASSWORD=$(terraform output -raw db_password 2>/dev/null || echo "")

    if [ ! -z "$DB_USERNAME" ] && [ ! -z "$DB_PASSWORD" ]; then
        mysql -h "$DB_ENDPOINT" \
              -P "$DB_PORT" \
              -u "$DB_USERNAME" \
              -p"$DB_PASSWORD" \
              -e "SELECT VERSION();" 2>/dev/null && \
            echo "✓ MySQL connection successful" || \
            echo "✗ MySQL connection failed"
    else
        echo "Database credentials not found in Terraform outputs"
    fi
else
    echo "MySQL client not installed. Please install mysql-client package to test database connectivity."
    echo "Windows: choco install mysql-cli"
    echo "Linux: sudo apt-get install mysql-client"
    echo "Mac: brew install mysql-client"
fi

# Summary and recommendations
echo -e "\nConnectivity Summary:"
echo "1. Instance Status: $(aws rds describe-db-instances --db-instance-identifier $INSTANCE_ID --query 'DBInstances[0].DBInstanceStatus' --output text)"
echo "2. Security Group: Inbound access on 3306 from ECS security group and specified IP"
echo "3. Subnet Group: Private subnets in $VPC_ID"
echo "4. Public Access: $PUBLICLY_ACCESSIBLE"

echo -e "\nTroubleshooting Tips:"
echo "1. Verify security group allows inbound traffic from your IP: ${MYIP:-'<your-ip>'}"
echo "2. Ensure ECS tasks are in the correct VPC and security group"
echo "3. Check route tables for proper routing to NAT Gateway or Internet Gateway"
echo "4. Verify NAT Gateway is properly configured for private subnets"