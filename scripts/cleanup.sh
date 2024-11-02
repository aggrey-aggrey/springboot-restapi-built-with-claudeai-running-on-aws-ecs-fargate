#!/bin/bash
# scripts/cleanup.sh

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

echo "WARNING: This will destroy all resources for the $ENV environment!"
echo "This includes:"
echo "- All application infrastructure (ECS, RDS, VPC, etc.)"
echo "- Terraform state bucket"
echo "- DynamoDB state lock table"
echo
echo "Are you absolutely sure you want to proceed? Type '$ENV' to confirm:"
read -r confirmation

if [ "$confirmation" != "$ENV" ]; then
    echo "Cleanup cancelled."
    exit 1
fi

echo "Starting cleanup process..."

# 1. Destroy infrastructure using the full path to tf.sh
echo "Destroying infrastructure..."
"$SCRIPT_DIR/tf.sh" "$ENV" destroy

# 2. Get backend resource names
BACKEND_CONFIG="$PROJECT_ROOT/terraform/environments/$ENV/backend.tfvars"
if [ -f "$BACKEND_CONFIG" ]; then
    BUCKET_NAME=$(grep bucket "$BACKEND_CONFIG" | cut -d'=' -f2 | tr -d ' "')
    DYNAMODB_TABLE=$(grep dynamodb_table "$BACKEND_CONFIG" | cut -d'=' -f2 | tr -d ' "')

    # 3. Clean up ECR images
    echo "Cleaning up ECR images..."
    REPO_NAME="author-books-$ENV"
    aws ecr describe-repositories --repository-names "$REPO_NAME" >/dev/null 2>&1 && {
        aws ecr delete-repository --repository-name "$REPO_NAME" --force
    } || echo "ECR repository not found or already deleted"

    # 4. Delete S3 bucket
    echo "Deleting Terraform state bucket..."
    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        aws s3 rb "s3://$BUCKET_NAME" --force
        echo "S3 bucket deleted successfully"
    else
        echo "S3 bucket not found or already deleted"
    fi

    # 5. Delete DynamoDB table
    echo "Deleting DynamoDB table..."
    if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" >/dev/null 2>&1; then
        aws dynamodb delete-table --table-name "$DYNAMODB_TABLE"
        echo "Waiting for DynamoDB table deletion..."
        aws dynamodb wait table-not-exists --table-name "$DYNAMODB_TABLE"
        echo "DynamoDB table deleted successfully"
    else
        echo "DynamoDB table not found or already deleted"
    fi

    # 6. Clean up local files
    echo "Cleaning up local Terraform files..."
    rm -rf "$PROJECT_ROOT/terraform/.terraform"
    rm -f "$PROJECT_ROOT/terraform/terraform.tfstate*"
    rm -f "$PROJECT_ROOT/terraform/tfplan"
else
    echo "Backend config not found at $BACKEND_CONFIG"
fi

echo "Cleanup complete!"
echo "The following resources have been destroyed:"
echo "- All application infrastructure"
echo "- S3 bucket: $BUCKET_NAME"
echo "- DynamoDB table: $DYNAMODB_TABLE"
echo "- ECR repository: $REPO_NAME"
echo "- Local Terraform files"

# Verify cleanup
echo -e "\nVerifying cleanup..."
echo "Checking for remaining resources..."

# Check S3 bucket
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "✓ S3 bucket deleted"
else
    echo "! S3 bucket still exists"
fi

# Check DynamoDB table
if ! aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" >/dev/null 2>&1; then
    echo "✓ DynamoDB table deleted"
else
    echo "! DynamoDB table still exists"
fi

# Check ECR repository
if ! aws ecr describe-repositories --repository-names "$REPO_NAME" >/dev/null 2>&1; then
    echo "✓ ECR repository deleted"
else
    echo "! ECR repository still exists"
fi

echo -e "\nNote: If any resources still exist, you may need to delete them manually through the AWS Console."