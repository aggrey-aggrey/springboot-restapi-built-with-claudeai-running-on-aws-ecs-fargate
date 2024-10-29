#!/bin/bash
# scripts/deploy.sh

set -e

# Check if environment is provided
ENV=${1:-dev}
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
    echo "Usage: $0 [dev|prod]"
    exit 1
fi

# Navigate to project root
cd "$(dirname "$0")/.."

# Load environment variables if .env file exists
ENV_FILE="terraform/environments/${ENV}/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

echo "Deploying to ${ENV} environment..."

# 1. Initialize and apply Terraform
echo "Initializing Terraform..."
cd terraform
terraform init -backend-config="environments/${ENV}/backend.tfvars"
terraform workspace select ${ENV} || terraform workspace new ${ENV}
terraform plan -var-file="environments/${ENV}/terraform.tfvars" -out=tfplan
terraform apply tfplan

# 2. Get database credentials and endpoints
DB_HOST=$(terraform output -raw rds_endpoint | cut -d: -f1)
DB_PORT=$(terraform output -raw rds_endpoint | cut -d: -f2)
DB_NAME=$(terraform output -raw db_name)

cd ..

# 3. Update application properties
./scripts/update-db-config.sh ${ENV}

# 4. Build Spring Boot application
echo "Building Spring Boot application..."
cd spring-boot-api
mvn clean package -P${ENV} \
    -DDB_HOST=$DB_HOST \
    -DDB_PORT=$DB_PORT \
    -DDB_NAME=$DB_NAME \
    -DDB_USERNAME=$DB_USERNAME \
    -DDB_PASSWORD=$DB_PASSWORD

# 5. Build and push Docker image
ECR_REPO=$(cd ../terraform && terraform output -raw ecr_repository_url)
docker build -t $ECR_REPO:latest .
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
docker push $ECR_REPO:latest

echo "Deployment completed successfully!"