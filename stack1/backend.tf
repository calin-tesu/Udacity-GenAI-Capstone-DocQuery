terraform {
    backend "s3" {
    # IMPORTANT: Replace 'YOUR_UNIQUE_SUFFIX' with your AWS Account ID or another unique string.
    # This bucket must exist before running 'terraform init'.
    bucket = "udacity-genai-capstone-tfstate-YOUR_AWS_ACCOUNT_ID" # Replace YOUR_AWS_ACCOUNT_ID with your actual AWS Account ID
    region = "us-west-2"
    key = "foundation/terraform.tfstate"
    encrypt = true
    dynamodb_table = "terraform-state-lock-YOUR_AWS_ACCOUNT_ID" # Replace YOUR_AWS_ACCOUNT_ID with your actual AWS Account ID
  }
}
