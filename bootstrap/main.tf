#
# This Terraform stack provisions the S3 bucket for Terraform state files
# and a DynamoDB table for state locking.
# This is a bootstrap stack that must be deployed before stack1 and stack2.
#

provider "aws" {
  region = var.aws_region
}

# Data source to fetch the current AWS Account ID, ensuring global uniqueness for bucket names.
data "aws_caller_identity" "current" {}

locals {
  # S3 bucket names must be globally unique across all of AWS.
  # Appending the Account ID ensures yours won't collide with someone else's.
  tfstate_bucket_name = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}"
  # DynamoDB table names also need to be unique within a region.
  dynamodb_table_name = "${var.project_name}-state-lock-${data.aws_caller_identity.current.account_id}"
}

# Resource for the S3 bucket to store Terraform state files.
resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = local.tfstate_bucket_name
  acl    = "private" # Always keep your state bucket private

  tags = {
    Name        = "Terraform State Bucket"
    Environment = var.environment
    ManagedBy   = "Terraform-Bootstrap"
  }
}

# Enable versioning on the state bucket. This is CRUCIAL for recovery in case of accidental state corruption.
resource "aws_s3_bucket_versioning" "terraform_state_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for the state bucket. Terraform state can contain sensitive data.
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_bucket_encryption" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access to the state bucket. This is a critical security measure.
resource "aws_s3_bucket_public_access_block" "terraform_state_bucket_public_access_block" {
  bucket = aws_s3_bucket.terraform_state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Resource for the DynamoDB table to provide state locking.
# This prevents multiple users/processes from concurrently modifying the state,
# which could lead to corruption.
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = local.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST" # Cost-effective for low usage
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = var.environment
    ManagedBy   = "Terraform-Bootstrap"
  }
}

# Output the names of the created resources for easy reference.
output "tfstate_bucket_name" {
  description = "The name of the S3 bucket used for Terraform state."
  value       = aws_s3_bucket.terraform_state_bucket.bucket
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table used for Terraform state locking."
  value       = aws_dynamodb_table.terraform_state_lock.name
}
