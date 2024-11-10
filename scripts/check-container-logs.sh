s#!/bin/bash
 # scripts/check-container-logs.sh

 set -e

 ENV=${1:-dev}
 APP_NAME="author-books-api"

 echo "Checking ECS logs..."

 # List all log groups and find ours
 echo "Finding log group..."
 LOG_GROUPS=$(aws logs describe-log-groups \
     --query "logGroups[?contains(logGroupName, '${APP_NAME}')].logGroupName" \
     --output text)

 if [ -z "$LOG_GROUPS" ]; then
     echo "No log groups found for $APP_NAME"
     exit 1
 fi

 # For each log group
 for LOG_GROUP in $LOG_GROUPS; do
     echo -e "\nChecking log group: $LOG_GROUP"

     # Get the latest log stream
     LATEST_STREAM=$(aws logs describe-log-streams \
         --log-group-name "$LOG_GROUP" \
         --order-by LastEventTime \
         --descending \
         --limit 1 \
         --query 'logStreams[0].logStreamName' \
         --output text)

     if [ "$LATEST_STREAM" = "None" ] || [ -z "$LATEST_STREAM" ]; then
         echo "No log streams found"
         continue
     fi

     echo "Latest log stream: $LATEST_STREAM"
     echo -e "\nRecent logs:"
     aws logs get-log-events \
         --log-group-name "$LOG_GROUP" \
         --log-stream-name "$LATEST_STREAM" \
         --limit 100 \
         --query 'events[*].{timestamp:timestamp,message:message}' \
         --output table
 done

 # Show task status
 echo -e "\nECS Task Status:"
 aws ecs list-tasks \
     --cluster "${APP_NAME}-cluster-${ENV}" \
     --query 'taskArns[]' \
     --output text | \
 while read -r task_arn; do
     if [ ! -z "$task_arn" ]; then
         aws ecs describe-tasks \
             --cluster "${APP_NAME}-cluster-${ENV}" \
             --tasks "$task_arn" \
             --query 'tasks[].{taskArn:taskArn,lastStatus:lastStatus,desiredStatus:desiredStatus,stoppedReason:stoppedReason,containers:containers[].{name:name,lastStatus:lastStatus,exitCode:exitCode,reason:reason}}'
     fi
 done
 Last edited 1 minute ago


