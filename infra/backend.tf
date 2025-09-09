# infra/backend.tf

terraform {
  backend "s3" {
    bucket         = "your-unique-terraform-state-bucket-name" # Use the same bucket name from above
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
  }
}
