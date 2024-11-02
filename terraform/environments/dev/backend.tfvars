bucket         = "terraform-state-author-books-dev"
key            = "author-books/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "terraform-state-lock-dev"
encrypt        = true
