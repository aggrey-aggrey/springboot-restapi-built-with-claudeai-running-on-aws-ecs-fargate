# terraform/provider.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Updated to use AWS provider version 5
    }
  }

  backend "s3" {
    # Empty block that will be configured via backend.tfvars
  }
}

provider "aws" {
  region = var.aws_region
}