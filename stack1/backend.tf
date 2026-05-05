terraform {
  backend "s3" {
    # IMPORTANT: Replace 'YOUR_UNIQUE_SUFFIX' with your AWS Account ID or another unique string.
    # This bucket must exist before running 'terraform init'.
    bucket = "udacity-genai-capstone-tfstate-us-west-2-YOUR_UNIQUE_SUFFIX"
    region = "us-west-2"
    key = "foundation/terraform.tfstate"
  }
}