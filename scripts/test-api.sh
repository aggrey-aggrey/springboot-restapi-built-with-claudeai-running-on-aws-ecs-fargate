#!/bin/bash
# scripts/test-api.sh

# Get the project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Get environment
ENV=${1:-dev}

# Navigate to terraform directory
cd "$PROJECT_ROOT/terraform"

# Get the ALB endpoint
ALB_ENDPOINT=$(terraform output -raw api_endpoint)

# Test endpoints
echo "Testing API endpoints..."
echo "ALB Endpoint: http://$ALB_ENDPOINT"

# Test authors endpoint
echo -e "\nTesting /api/v1/authors endpoint:"
curl -v "http://$ALB_ENDPOINT/api/v1/authors"

# Additional tests can be added here