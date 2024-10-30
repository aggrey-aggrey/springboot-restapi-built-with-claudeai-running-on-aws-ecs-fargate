#!/bin/bash
# scripts/verify-destruction.sh

set -e

ENVIRONMENT=$1
REGION=$2

echo "Verifying resource destruction in ${ENVIRONMENT} environment (${REGION})..."

# Function to check resource existence
check_resource() {
    local resource_type=$1
    local command=$2
    local query=$3

    echo "Checking ${resource_type}..."
    local result=$(eval "${command}")
    if [ ! -z "$result" ]; then
        echo "ERROR: Found remaining ${resource_type}: ${result}"
        return 1
    fi
    echo "✓ No ${resource_type} found"
    return 0
}

# Check all resource types
check_resource "ECS Services" \
    "aws ecs list-services --cluster author-book-cluster-${ENVIRONMENT} --region ${REGION} --query 'serviceArns[]' --output text" || EXIT_CODE=1

check_resource "RDS Instances" \
    "aws rds describe-db-instances --region ${REGION} --query \"DBInstances[?DBInstanceIdentifier=='author-book-db-${ENVIRONMENT}'].DBInstanceIdentifier\" --output text" || EXIT_CODE=1

check_resource "Load Balancers" \
    "aws elbv2 describe-load-balancers --region ${REGION} --query \"LoadBalancers[?contains(LoadBalancerName, 'author-book-alb-${ENVIRONMENT}')].LoadBalancerName\" --output text" || EXIT_CODE=1

if [ "$EXIT_CODE" != "0" ]; then
    echo "❌ Some resources were not properly destroyed. Please check manually."
    exit 1
else
    echo "✅ All resources were successfully destroyed!"
fi
Last edited 2 days ago