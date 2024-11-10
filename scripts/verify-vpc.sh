#!/bin/bash
# scripts/verify-vpc.sh

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

echo "Verifying VPC Configuration..."

# Get VPC ID
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=${APP_NAME}-vpc-${ENV}" \
    --query 'Vpcs[0].VpcId' \
    --output text)

if [ -z "$VPC_ID" ] || [ "$VPC_ID" == "None" ]; then
    echo "❌ VPC not found!"
    exit 1
fi

echo "✅ VPC found: $VPC_ID"

# Check subnets
echo -e "\nChecking Subnets..."
echo "Public Subnets:"
aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=*public*" \
    --query 'Subnets[].{SubnetId:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone,State:State}'

echo -e "\nPrivate Subnets:"
aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=*private*" \
    --query 'Subnets[].{SubnetId:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone,State:State}'

# Check NAT Gateway
echo -e "\nChecking NAT Gateway..."
aws ec2 describe-nat-gateways \
    --filter "Name=vpc-id,Values=$VPC_ID" \
    --query 'NatGateways[].{State:State,SubnetId:SubnetId}'

# Check Route Tables
echo -e "\nChecking Route Tables..."
aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'RouteTables[].{RouteTableId:RouteTableId,Routes:Routes}'

# Check Security Groups
echo -e "\nChecking Security Groups..."
aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'SecurityGroups[].{GroupId:GroupId,GroupName:GroupName,Description:Description}'

# Get RDS subnet group
echo -e "\nChecking RDS Subnet Group..."
aws rds describe-db-subnet-groups \
    --query 'DBSubnetGroups[?VpcId==`'$VPC_ID'`]'

echo -e "\nVerification Summary:"
echo "1. Make sure private subnets exist and have proper routing to NAT Gateway"
echo "2. Verify security group allows inbound traffic on port 3306"
echo "3. Check that RDS subnet group contains valid private subnets"
echo "4. Ensure NAT Gateway is active and has proper routing"