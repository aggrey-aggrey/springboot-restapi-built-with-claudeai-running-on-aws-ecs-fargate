#!/bin/bash
# scripts/monitor-api.sh

ENV=${1:-dev}

# Get service details
CLUSTER=$(./scripts/tf.sh $ENV output ecs_cluster_name)
SERVICE=$(./scripts/tf.sh $ENV output ecs_service_name)
ALB_ENDPOINT=$(./scripts/tf.sh $ENV output api_endpoint)

echo "Monitoring API deployment..."
echo "Environment: $ENV"
echo "ALB Endpoint: http://$ALB_ENDPOINT"

# Check service status
echo -e "\nECS Service Status:"
aws ecs describe-services \
  --cluster $CLUSTER \
  --services $SERVICE \
  --query 'services[0].{status:status,runningCount:runningCount,desiredCount:desiredCount,pendingCount:pendingCount}'

# Check target health
echo -e "\nTarget Group Health:"
TARGET_GROUP=$(aws elbv2 describe-target-groups \
  --names ${APP_NAME:-author-books}-tg-$ENV \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

aws elbv2 describe-target-health \
  --target-group-arn $TARGET_GROUP

# Test API endpoint
echo -e "\nAPI Health Check:"
curl -s -o /dev/null -w "%{http_code}" "http://$ALB_ENDPOINT/api/v1/authors"