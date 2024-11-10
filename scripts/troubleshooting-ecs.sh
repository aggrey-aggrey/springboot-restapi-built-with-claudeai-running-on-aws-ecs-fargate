#!/bin/bash
# scripts/troubleshoot-ecs.sh

set -e

# Get the project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Default environment
ENV=${1:-dev}
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
    echo "Usage: $0 [dev|prod]"
    exit 1
fi

# Navigate to terraform directory
cd "$PROJECT_ROOT/terraform"

echo "Gathering resource information..."
echo "--------------------------------"

# Function to safely get Terraform output
get_terraform_output() {
    local output_name=$1
    local default_value=${2:-""}

    if terraform output -raw "$output_name" 2>/dev/null; then
        return 0
    else
        echo "$default_value"
        return 1
    fi
}

# Use the correct app name that matches your infrastructure
APP_NAME="author-books-api"

# Get resource names from Terraform
echo "Getting Terraform outputs..."
CLUSTER_NAME="${APP_NAME}-cluster-${ENV}"
SERVICE_NAME="${APP_NAME}-service-${ENV}"
ALB_NAME="${APP_NAME}-alb-${ENV}"
TG_NAME="${APP_NAME}-tg-${ENV}"

echo "Resource Names:"
echo "- Cluster: $CLUSTER_NAME"
echo "- Service: $SERVICE_NAME"
echo "- ALB: $ALB_NAME"
echo "- Target Group: $TG_NAME"

echo -e "\n1. Checking ECS Cluster..."
if aws ecs describe-clusters --clusters "$CLUSTER_NAME" >/dev/null 2>&1; then
    echo "✓ Cluster exists"

    echo -e "\n2. Checking ECS Service Status..."
    aws ecs describe-services \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME" \
        --query 'services[0].{status:status,runningCount:runningCount,desiredCount:desiredCount,pendingCount:pendingCount,events:events[0:3].message}'

    echo -e "\n3. Checking Tasks and Container Status..."
    TASKS=$(aws ecs list-tasks \
        --cluster "$CLUSTER_NAME" \
        --service-name "$SERVICE_NAME" \
        --query 'taskArns[]' \
        --output text)

    if [ ! -z "$TASKS" ] && [ "$TASKS" != "None" ]; then
        echo "Task Details:"
        aws ecs describe-tasks \
            --cluster "$CLUSTER_NAME" \
            --tasks $TASKS \
            --query 'tasks[].{taskArn:taskArn,lastStatus:lastStatus,healthStatus:healthStatus,stoppedReason:stoppedReason,containers:containers[].{name:name,lastStatus:lastStatus,reason:reason,exitCode:exitCode}}'

        echo -e "\nContainer Logs for Failed Tasks:"
        for task in $TASKS; do
            TASK_ID=$(basename $task)
            echo "Logs for task $TASK_ID:"
            aws logs get-log-events \
                --log-group-name "/ecs/${APP_NAME}-${ENV}" \
                --log-stream-name "ecs/${APP_NAME}/${TASK_ID}" \
                --limit 20 \
                --query 'events[*].message' \
                --output text || echo "No logs found"
        done
    else
        echo "No tasks found running"

        echo -e "\nChecking recent stopped tasks..."
        STOPPED_TASKS=$(aws ecs list-tasks \
            --cluster "$CLUSTER_NAME" \
            --service-name "$SERVICE_NAME" \
            --desired-status STOPPED \
            --query 'taskArns[]' \
            --output text)

        if [ ! -z "$STOPPED_TASKS" ] && [ "$STOPPED_TASKS" != "None" ]; then
            echo "Recent stopped task details:"
            aws ecs describe-tasks \
                --cluster "$CLUSTER_NAME" \
                --tasks $STOPPED_TASKS \
                --query 'tasks[].{taskArn:taskArn,lastStatus:lastStatus,stoppedReason:stoppedReason,containers:containers[].{name:name,reason:reason,exitCode:exitCode}}'
        fi
    fi
else
    echo "✗ Cluster not found"
fi

echo -e "\n4. Checking Load Balancer..."
if aws elbv2 describe-load-balancers --names "$ALB_NAME" >/dev/null 2>&1; then
    echo "✓ Load Balancer exists"
    aws elbv2 describe-load-balancers \
        --names "$ALB_NAME" \
        --query 'LoadBalancers[0].{DNSName:DNSName,State:State.Code,Scheme:Scheme}'
else
    echo "✗ Load Balancer not found"
fi

echo -e "\n5. Checking Target Group..."
if TG_ARN=$(aws elbv2 describe-target-groups --names "$TG_NAME" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null); then
    echo "✓ Target Group exists"
    echo "Checking target health..."
    aws elbv2 describe-target-health \
        --target-group-arn "$TG_ARN" \
        --query 'TargetHealthDescriptions[].{Target:Target.Id,Health:TargetHealth.State,Reason:TargetHealth.Reason,Description:TargetHealth.Description}'
else
    echo "✗ Target Group not found"
fi

echo -e "\n6. Checking CloudWatch Logs..."
LOG_GROUP="/ecs/${APP_NAME}-${ENV}"
if aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" >/dev/null 2>&1; then
    echo "✓ Log Group exists"
    echo "Recent logs:"
    aws logs tail "$LOG_GROUP" --since 5m || echo "No recent logs found"
else
    echo "✗ Log Group not found"
fi

echo -e "\nDiagnostic Summary:"
echo "-------------------"
if [ "$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME" --query 'services[0].runningCount' --output text)" = "0" ]; then
    echo "⚠️  Service has 0 running tasks. Common causes:"
    echo "1. Task definition issues (check environment variables, container configuration)"
    echo "2. Container crashes (check CloudWatch logs)"
    echo "3. Health check failures (verify health check path and container health)"
    echo "4. Networking issues (check security groups, VPC configuration)"

    echo -e "\nTry these commands:"
    echo "1. Force new deployment:"
    echo "   aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment"
    echo "2. View detailed logs:"
    echo "   aws logs tail $LOG_GROUP --follow"
    echo "3. Check security groups:"
    echo "   aws ec2 describe-security-groups --filters Name=group-name,Values=${APP_NAME}-*-${ENV}"
fi

echo -e "\nResource Details for AWS Console:"
echo "--------------------------------"
echo "ECS Cluster: $CLUSTER_NAME"
echo "ECS Service: $SERVICE_NAME"
echo "Load Balancer: $ALB_NAME"
echo "Target Group: $TG_NAME"
echo "Log Group: $LOG_GROUP"