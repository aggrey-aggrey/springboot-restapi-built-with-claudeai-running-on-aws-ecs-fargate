# terraform/environments/dev/terraform.tfvars
environment = "dev"
aws_region  = "us-west-2"
app_name    = "author-books-api"
db_name     = "authors_books_dev"

vpc_cidr        = "10.0.0.0/16"
private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

container_cpu       = 256        # For dev
container_memory    = 512        # For dev
health_check_path   = "/actuator/health"

db_multi_az           = false
db_deletion_protection = false
db_storage_encrypted  = true
db_storage_type       = "gp3"

tags = {
  Environment = "dev"
  Project     = "author-books-api"
  ManagedBy   = "terraform"
}

/*
environment              = "dev"
aws_region              = "us-west-2"
vpc_cidr                = "10.0.0.0/16"
db_instance_class       = "db.t3.micro"
db_allocated_storage    = 20
enable_deletion_protection = false
multi_az               = false*/