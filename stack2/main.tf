#
# This Terraform stack provisions the Amazon Bedrock Knowledge Base.
# It depends on the infrastructure created in stack1 and retrieves its outputs
# via a remote state data source.
#

# The bucket that store the values generated on stack1
terraform {
  backend "s3" {
    bucket = "udacity-genai-capstone-tfstate-us-west-2-YOUR_UNIQUE_SUFFIX" # Must match the bucket name used in stack1/backend.tf
    region = "us-west-2"
    key    = "foundation/terraform.tfstate" # Must match the key used in stack1/backend.tf
  }
}

provider "aws" {
  region = "us-west-2"  
}

# Data source to retrieve outputs from stack1's remote state
data "terraform_remote_state" "stack1_foundation" {
  backend = "s3"
  config = {
    bucket = "udacity-genai-capstone-tfstate-us-west-2-YOUR_UNIQUE_SUFFIX" # Must match the bucket name used in stack1/backend.tf
    key    = "foundation/terraform.tfstate" # Must match the key used in stack1/backend.tf
    region = "us-west-2"
  }
}

module "bedrock_kb" {
  source = "../modules/bedrock_kb" 

  knowledge_base_name        = "my-bedrock-kb"
  knowledge_base_description = "Knowledge base connected to Aurora Serverless database"

  aurora_arn        = data.terraform_remote_state.stack1_foundation.outputs.aurora_arn
  aurora_db_name    = "myapp"
  aurora_endpoint   = data.terraform_remote_state.stack1_foundation.outputs.db_endpoint
  aurora_table_name = "bedrock_integration.bedrock_kb"
  aurora_primary_key_field = "id"
  aurora_metadata_field = "metadata"
  aurora_text_field = "chunks"
  aurora_verctor_field = "embedding"
  aurora_username   = "dbadmin"
  aurora_secret_arn = data.terraform_remote_state.stack1_foundation.outputs.rds_secret_arn
  s3_bucket_arn = data.terraform_remote_state.stack1_foundation.outputs.s3_bucket_name
}