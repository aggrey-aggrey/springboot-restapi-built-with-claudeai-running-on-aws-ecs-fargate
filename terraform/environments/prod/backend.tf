terraform {
  backend "s3" {
    bucket = "prod-author-books-terraform-state-bucket"
    key    = "author-books-api/terraform.tfstate"
    region = "us-west-2"

    dynamodb_table = "authorbooks-prod-terraform-state-lock"
    encrypt        = true
  }
}