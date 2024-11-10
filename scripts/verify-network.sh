#!/bin/bash
# scripts/verify-network.sh

set -e

ENV=${1:-dev}
APP_NAME="author-books-api"

echo "Performing comprehensive network verification..."

# Get VPC details
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name:tag:Name,Values=${APP_NAME}-vpc-${ENV}" \
    --query 'Vpcs[0].VpcId' \
    --output text)

echo "1. VPC Configuration"
echo "VPC ID: $VPC_ID"

# Check NAT Gateway
echo -e "\n2. NAT Gateway Status:"
aws ec2 describe-nat-gateways \
    --filter "Name=vpc-id,Values=$VPC_ID" \
    --query 'NatGateways[].{State:State,SubnetId:SubnetId}'

# Check Route Tables
echo -e "\n3. Route Tables:"
for subnet in $(aws rds describe-db-subnet-groups \
    --db-subnet-group-name "${APP_NAME}-${ENV}" \
    --query 'DBSubnetGroups[0].Subnets[].SubnetId' \
    --output text); do
    echo "Routes for subnet $subnet:"
    aws ec2 describe-route-tables \
        --filters "Name=association.subnet-id,Values=$subnet" \
        --query 'RouteTables[].Routes'
done

# Check Network ACLs
echo -e "\n4. Network ACLs:"
for subnet in $(aws rds describe-db-subnet-groups \
    --db-subnet-group-name "${APP_NAME}-${ENV}" \
    --query 'DBSubnetGroups[0].Subnets[].SubnetId' \
    --output text); do
    echo "NACLs for subnet $subnet:"
    aws ec2 describe-network-acls \
        --filters "Name=association.subnet-id,Values=$subnet" \
        --query 'NetworkAcls[].Entries'
done

# Test Connectivity
echo -e "\n5. Testing Database Connectivity:"
DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "${APP_NAME}-db-${ENV}" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

echo "Database endpoint: $DB_ENDPOINT"
echo "Testing TCP connection..."
nc -zv -w 5 $DB_ENDPOINT 3306 || echo "Connection failed"

# Check Security Groups
echo -e "\n6. Security Group Rules:"
SG_ID=$(aws rds describe-db-instances \
    --db-instance-identifier "${APP_NAME}-db-${ENV}" \
    --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
    --output text)

aws ec2 describe-security-groups \
    --group-ids "$SG_ID" \
    --query 'SecurityGroups[0].IpPermissions'

echo -e "\nVerification complete. Check the output above for any issues."
Last edited