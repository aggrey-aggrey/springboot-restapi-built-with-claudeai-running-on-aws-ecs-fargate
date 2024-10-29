terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "author-books-api/terraform.tfstate"
    region = "us-west-2"

    dynamodb_table = "prod-terraform-state-lock"
    encrypt        = true
  }
}