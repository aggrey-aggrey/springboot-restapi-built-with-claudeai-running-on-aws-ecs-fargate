#!/bin/bash
# scripts/docker-build-push.sh

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

# Check if Dockerfile exists in root directory
if [ ! -f "$PROJECT_ROOT/Dockerfile" ]; then
    echo "Error: Dockerfile not found in project root: $PROJECT_ROOT"
    exit 1
fi

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
AWS_REGION="us-west-2"  # Or get from terraform output
APP_NAME="author-books-api"
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}-${ENV}"

echo "Getting ECR repository information..."
echo "Repository: ${ECR_REPO}"

# Build Spring Boot application
echo "Building Spring Boot application..."
cd "$PROJECT_ROOT"

# Check if pom.xml exists
if [ ! -f "pom.xml" ]; then
    echo "Error: pom.xml not found in $PROJECT_ROOT"
    exit 1
fi

# Build the application
./mvnw clean package -DskipTests

# Authenticate Docker to ECR
echo "Authenticating with ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build Docker image
echo "Building Docker image..."
docker build -t ${ECR_REPO}:latest .

# Push to ECR
echo "Pushing to ECR..."
docker push ${ECR_REPO}:latest

echo "Successfully built and pushed image to ECR"
echo "Image: ${ECR_REPO}:latest"

# Verify the push
echo -e "\nVerifying image in ECR..."
aws ecr describe-images \
    --repository-name ${APP_NAME}-${ENV} \
    --region ${AWS_REGION} \
    --query 'imageDetails[?imageTag==`latest`]'