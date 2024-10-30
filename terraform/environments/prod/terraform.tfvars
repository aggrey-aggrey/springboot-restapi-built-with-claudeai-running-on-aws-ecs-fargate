/** environment     = "prod"
aws_region      = "us-west-2"
db_name         = "author-books-db"
db_username     = "prod_user"
# Don't commit passwords to version control
db_password     = "dummy_password" **/

environment              = "prod"
aws_region              = "us-west-2"
vpc_cidr                = "10.0.0.0/16"
db_instance_class       = "db.t3.medium"
db_allocated_storage    = 50
enable_deletion_protection = true
multi_az               = true