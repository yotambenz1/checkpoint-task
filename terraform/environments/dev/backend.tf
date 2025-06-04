terraform {
  backend "s3" {
    bucket         = "checkpoint-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "checkpoint-terraform-locks"
    encrypt        = true
  }
} 