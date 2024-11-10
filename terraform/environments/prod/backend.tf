terraform {
  backend "s3" {
    bucket = "authorbooks-s3-terraform-state-file-bucket-prod"
    key    = "author-books-api/terraform.tfstate"
    region = "us-west-2"

    dynamodb_table = "authorbooks-terraform-state-lock-file-prod"
    encrypt        = true
  }
}