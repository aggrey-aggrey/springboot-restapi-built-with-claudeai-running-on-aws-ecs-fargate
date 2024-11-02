#!/bin/bash
# scripts/tf-init.sh

# Get the project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Check if environment is provided
ENV=${1:-dev}
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
    echo "Usage: $0 [dev|prod]"
    exit 1
fi

# Navigate to terraform directory
cd "$PROJECT_ROOT/terraform"

# Check if backend config exists
BACKEND_CONFIG="environments/$ENV/backend.tfvars"
if [ ! -f "$BACKEND_CONFIG" ]; then
    echo "Error: Backend configuration not found at: $BACKEND_CONFIG"
    echo "Creating default backend configuration..."

    # Create directory if it doesn't exist
    mkdir -p "environments/$ENV"

    # Create default backend configuration
    cat > "$BACKEND_CONFIG" << EOF
bucket         = "terraform-state-author-books-$ENV"
key            = "author-books/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "terraform-state-lock-$ENV"
encrypt        = true
EOF

    echo "Created default backend configuration at: $BACKEND_CONFIG"
fi

# Initialize Terraform
echo "Initializing Terraform with backend config: $BACKEND_CONFIG"
terraform init -backend-config="$BACKEND_CONFIG"

# Return to original directory
cd - > /dev/null