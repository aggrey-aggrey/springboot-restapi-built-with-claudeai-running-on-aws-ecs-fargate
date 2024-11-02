# terraform/variables.tf

# Environment Variables
variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

# Database Variables
variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Database master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage in GB"
  type        = number
}

variable "db_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
}

variable "db_multi_az" {
  description = "If the RDS instance should be multi-AZ"
  type        = bool
  default     = false
}

variable "db_storage_type" {
  description = "Storage type for RDS instance"
  type        = string
  default     = "gp3"
}

variable "db_storage_encrypted" {
  description = "Whether the RDS storage should be encrypted"
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "If the RDS instance should have deletion protection enabled"
  type        = bool
  default     = false
}

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

# Application Variables
variable "app_name" {
  description = "Application name"
  type        = string
  default     = "redcell.io-author-books-api"
}

# Tags
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# ECS Variables
variable "container_cpu" {
  description = "Container CPU units (1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Container memory in MB"
  type        = number
  default     = 512
}

variable "health_check_path" {
  description = "Health check path for the application"
  type        = string
  default     = "/actuator/health"
}