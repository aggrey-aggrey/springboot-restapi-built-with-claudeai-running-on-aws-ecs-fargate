#!/bin/bash
# scripts/setup-aws.sh

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

# AWS Region
AWS_REGION="us-west-2"  # Change this to your preferred region

# Resource names
BUCKET_NAME="terraform-state-author-books-$ENV"
DYNAMODB_TABLE="terraform-state-lock-$ENV"

echo "Setting up AWS infrastructure for environment: $ENV"

# Check AWS CLI configuration
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "Error: AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

# Create S3 bucket
echo "Creating S3 bucket: $BUCKET_NAME"
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    # Create bucket with specified region
    if [ "$AWS_REGION" = "us-east-1" ]; then
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$AWS_REGION"
    else
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$AWS_REGION" \
            --create-bucket-configuration LocationConstraint="$AWS_REGION"
    fi

    # Wait for bucket to be created
    echo "Waiting for bucket to be created..."
    aws s3api wait bucket-exists --bucket "$BUCKET_NAME"

    # Enable versioning
    echo "Enabling bucket versioning..."
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled

    # Enable encryption
    echo "Enabling bucket encryption..."
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'

    # Block public access
    echo "Blocking public access..."
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
else
    echo "Bucket $BUCKET_NAME already exists"
fi

# Create DynamoDB table
echo "Creating DynamoDB table: $DYNAMODB_TABLE"
if ! aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" 2>/dev/null; then
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
        --region "$AWS_REGION"

    echo "Waiting for DynamoDB table to be created..."
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE"
else
    echo "DynamoDB table $DYNAMODB_TABLE already exists"
fi

# Update backend configuration
BACKEND_CONFIG="$PROJECT_ROOT/terraform/environments/$ENV/backend.tfvars"
mkdir -p "$(dirname "$BACKEND_CONFIG")"

echo "Creating backend configuration..."
cat > "$BACKEND_CONFIG" << EOF
bucket         = "$BUCKET_NAME"
key            = "author-books/terraform.tfstate"
region         = "$AWS_REGION"
dynamodb_table = "$DYNAMODB_TABLE"
encrypt        = true
EOF

echo "AWS infrastructure setup complete!"
echo "Created/Updated:"
echo "- S3 Bucket: $BUCKET_NAME"
echo "- DynamoDB Table: $DYNAMODB_TABLE"
echo "- Backend Config: $BACKEND_CONFIG"
Last edited 9 hours ago