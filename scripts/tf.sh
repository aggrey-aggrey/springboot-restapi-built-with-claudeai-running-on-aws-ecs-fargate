#!/bin/bash
# scripts/tf.sh

set -e

# Get the project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Default environment is dev
ENV=${1:-dev}
ACTION=${2:-plan}

# Validate environment
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
    echo "Usage: $0 [dev|prod] [init|plan|apply|destroy]"
    exit 1
fi

# Navigate to terraform directory
cd "$PROJECT_ROOT/terraform"

# Function to check if backend config exists
check_backend_config() {
    local backend_config="environments/$ENV/backend.tfvars"
    if [ ! -f "$backend_config" ]; then
        echo "Error: Backend configuration not found at: $backend_config"
        exit 1
    fi
}

# Function to check if var files exist
check_var_files() {
    local tf_vars="environments/$ENV/terraform.tfvars"
    local secrets_vars="environments/$ENV/secrets.tfvars"

    if [ ! -f "$tf_vars" ]; then
        echo "Error: terraform.tfvars not found at: $tf_vars"
        exit 1
    fi

    if [ ! -f "$secrets_vars" ]; then
        echo "Error: secrets.tfvars not found at: $secrets_vars"
        exit 1
    fi
}

# Execute Terraform commands
case $ACTION in
    init)
        check_backend_config
        terraform init -backend-config="environments/$ENV/backend.tfvars"
        ;;
    plan)
        check_var_files
        terraform plan \
            -var-file="environments/$ENV/terraform.tfvars" \
            -var-file="environments/$ENV/secrets.tfvars" \
            -out=tfplan
        ;;
    apply)
        check_var_files
        terraform apply tfplan
        ;;
    destroy)
        check_var_files
        terraform destroy \
            -var-file="environments/$ENV/terraform.tfvars" \
            -var-file="environments/$ENV/secrets.tfvars"
        ;;
    *)
        echo "Invalid action. Use: init, plan, apply, or destroy"
        exit 1
        ;;
esac

# Return to original directory
cd - > /dev/null
