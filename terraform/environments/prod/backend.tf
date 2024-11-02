terraform {
  backend "s3" {
    bucket = "prod-authorbooks-s3-terraform-state-file-bucket"
    key    = "author-books-api/terraform.tfstate"
    region = "us-west-2"

    dynamodb_table = "prod-authorbooks-terraform-state-lock-file"
    encrypt        = true
  }
}