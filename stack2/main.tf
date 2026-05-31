#
# This Terraform stack provisions the Amazon Bedrock Knowledge Base.
# It depends on the infrastructure created in stack1 and retrieves its outputs
# via a remote state data source.
#


# The bucket that store the values generated on stack1
terraform { # This backend configuration is for stack2's own state file
  backend "s3" {
    bucket = "docquery-tfstate-YOUR_AWS_ACCOUNT_ID" # Replace YOUR_AWS_ACCOUNT_ID with your actual AWS Account ID
    region = "us-west-2" # Note: Variables are not allowed in backend blocks
    key    = "bedrock_kb/terraform.tfstate" # Unique key for stack2's state file
    dynamodb_table = "docquery-state-lock-YOUR_AWS_ACCOUNT_ID" # Replace YOUR_AWS_ACCOUNT_ID with your actual AWS Account ID
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source to retrieve outputs from stack1's remote state
data "terraform_remote_state" "stack1_foundation" {
  backend = "s3"
  config = { # This configuration points to stack1's state file
    bucket = "docquery-tfstate-YOUR_AWS_ACCOUNT_ID" # Replace YOUR_AWS_ACCOUNT_ID with your actual AWS Account ID
    key    = "foundation/terraform.tfstate" # Must match the key used in stack1/backend.tf
    region = var.aws_region
  }
}

module "bedrock_kb" {
  source = "../modules/bedrock_kb" 

  # Using project_name and environment ensures the KB follows the same naming convention as Stack 1
  knowledge_base_name        = "${var.project_name}-${var.environment}-kb"
  knowledge_base_description = var.knowledge_base_description

  aurora_arn        = data.terraform_remote_state.stack1_foundation.outputs.aurora_arn
  aurora_db_name    = data.terraform_remote_state.stack1_foundation.outputs.db_name
  aurora_endpoint   = data.terraform_remote_state.stack1_foundation.outputs.db_endpoint
  aurora_table_name = data.terraform_remote_state.stack1_foundation.outputs.aurora_table_name
  aurora_primary_key_field = "id"
  aurora_metadata_field = "metadata"
  aurora_text_field = "chunks"
  aurora_vector_field = "embedding"
  aurora_username   = data.terraform_remote_state.stack1_foundation.outputs.db_username
  aurora_secret_arn = data.terraform_remote_state.stack1_foundation.outputs.rds_secret_arn
  s3_bucket_arn = data.terraform_remote_state.stack1_foundation.outputs.s3_bucket_arn
}