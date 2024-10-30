#!/bin/bash
# scripts/check-resources.sh

set -e

ENVIRONMENT=$1
REGION=$2

echo "Checking for running resources in ${ENVIRONMENT} environment (${REGION})..."

# Check ECS Services
echo "Checking ECS services..."
RUNNING_SERVICES=$(aws ecs list-services --cluster author-book-cluster-${ENVIRONMENT} --region ${REGION} --query 'serviceArns[]' --output text)
if [ ! -z "$RUNNING_SERVICES" ]; then
    echo "WARNING: Found running ECS services: ${RUNNING_SERVICES}"
fi

# Check RDS Instances
echo "Checking RDS instances..."
RUNNING_RDS=$(aws rds describe-db-instances --region ${REGION} --query "DBInstances[?DBInstanceIdentifier=='author-book-db-${ENVIRONMENT}'].DBInstanceIdentifier" --output text)
if [ ! -z "$RUNNING_RDS" ]; then
    echo "WARNING: Found RDS instance: ${RUNNING_RDS}"
fi

# Check Load Balancers
echo "Checking Load Balancers..."
RUNNING_LB=$(aws elbv2 describe-load-balancers --region ${REGION} --query "LoadBalancers[?contains(LoadBalancerName, 'author-book-alb-${ENVIRONMENT}')].LoadBalancerName" --output text)
if [ ! -z "$RUNNING_LB" ]; then
    echo "WARNING: Found Load Balancer: ${RUNNING_LB}"
fi
