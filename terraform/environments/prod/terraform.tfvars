/** environment     = "prod"
aws_region      = "us-west-2"
db_name         = "author-books-db"
db_username     = "prod_user"
# Don't commit passwords to version control
db_password     = "dummy_password"
vpc_cidr                = "10.0.0.0/16"
db_instance_class       = "db.t3.medium"
db_allocated_storage    = 50
enable_deletion_protection = true
multi_az               = true*/

# terraform/environments/prod/terraform.tfvars
environment = "prod"
aws_region  = "us-west-2"
app_name    = "author-books"
db_name     = "authors_books_prod"

vpc_cidr        = "10.0.0.0/16"
private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

container_cpu       = 1024       # For prod
container_memory    = 2048       # For prod
health_check_path   = "/actuator/health"

db_multi_az           = true
db_deletion_protection = true
db_storage_encrypted  = true
db_storage_type       = "gp3"

tags = {
  Environment = "prod"
  Project     = "author-books-api"
  ManagedBy   = "terraform"
}