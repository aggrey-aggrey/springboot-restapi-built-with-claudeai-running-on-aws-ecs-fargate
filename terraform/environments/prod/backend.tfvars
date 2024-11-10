bucket         = "terraform-state-author-books-prod"
key            = "author-books/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "terraform-state-lock-prod"
encrypt        = true
