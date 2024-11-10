/** environment     = "prod"
environment = "prod"
app_name    = "author-books-api"
aws_region  = "us-west-2"

# VPC Configuration
vpc_cidr        = "10.0.0.0/16"
private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

# ECS Configuration
container_cpu    = 1024
container_memory = 2048

# Database Connection (from manually created RDS)
db_host = "your-prod-rds-endpoint"
db_port = "3306"
db_name = "your_database_name"

tags = {
  Environment = "prod"
  Project = "author-books-api"
  ManagedBy = "terraform"
}