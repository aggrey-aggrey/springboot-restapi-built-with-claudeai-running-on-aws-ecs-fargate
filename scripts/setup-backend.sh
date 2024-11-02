#!/bin/bash
# scripts/setup-backend.sh

# Check if environment is provided
ENV=${1:-dev}
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
    echo "Usage: $0 [dev|prod]"
    exit 1
fi

# Set variables
BUCKET_NAME="dev-authorbooks-s3-terraform-state-file-bucket-$ENV"
DYNAMODB_TABLE="dev-authorbooks-terraform-state-lock-file-$ENV"
REGION="us-west-2"  # Change this to match your desired region

# Check if AWS CLI is configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "Error: AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

echo "Creating S3 bucket for Terraform state..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Bucket $BUCKET_NAME already exists"
else
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION"

    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled

    # Enable encryption
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
fi

echo "Creating DynamoDB table for state locking..."
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" 2>/dev/null; then
    echo "Table $DYNAMODB_TABLE already exists"
else
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
        --region "$REGION"
fi

# Create or update backend config file
BACKEND_CONFIG_DIR="../terraform/environments/$ENV"
mkdir -p "$BACKEND_CONFIG_DIR"

cat > "$BACKEND_CONFIG_DIR/backend.tfvars" << EOF
bucket         = "$BUCKET_NAME"
key            = "author-books-api/terraform.tfstate"
region         = "$REGION"
dynamodb_table = "$DYNAMODB_TABLE"
encrypt        = true
EOF

echo "Backend configuration complete!"
echo "Created/Updated: $BACKEND_CONFIG_DIR/backend.tfvars"