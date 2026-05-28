#
# This Terraform stack provisions the core infrastructure for the Bedrock POC application.
# It includes a VPC for network isolation, an Aurora Serverless database for data storage,
# and an S3 bucket for knowledge base documents.
#

# The "provider" block tells Terraform which cloud service we are using.
provider "aws" {
  region = var.aws_region
}

# A "module" is a reusable package of Terraform configurations. 
# Instead of writing hundreds of lines to set up a network, we use a verified 
# blueprint from the Terraform Registry.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  # CIDR block defines the IP address range for the entire network (10.0.0.0 to 10.0.255.255).
  cidr = var.vpc_cidr

  # Availability Zones (AZs) are isolated data centers within a region. 
  # Distributing subnets across 3 AZs provides "High Availability."
  azs             = var.vpc_azs
  
  # Private subnets: Resources here (like databases) have NO direct internet access.
  private_subnets = var.private_subnets
  
  # Public subnets: Resources here can be reached via the internet (using an Internet Gateway).
  public_subnets  = var.public_subnets

  # NAT Gateway: Allows resources in private subnets to reach out to the internet 
  # (e.g., to download updates) without allowing the internet to reach in.
  enable_nat_gateway = true
  single_nat_gateway = var.single_nat_gateway 

  # DNS settings allow AWS to give friendly hostnames to your resources (like db.example.com).
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

# This module points to a local folder you created (../modules/database).
# It abstracts the complexity of setting up a Serverless Aurora cluster.
module "aurora_serverless" {
  source = "../modules/database"

  cluster_identifier = "${var.project_name}-aurora"
  
  # We pass the outputs from the VPC module into this module. 
  # This creates a dependency: Terraform knows it must build the VPC before the DB.
  vpc_id             = module.vpc.vpc_id 
  subnet_ids         = module.vpc.private_subnets

  database_name    = var.db_name
  master_username  = var.db_username
  engine_version   = var.db_engine_version 
  
  # Aurora Serverless v2 scales based on ACUs (Aurora Capacity Units).
  max_capacity     = var.db_max_capacity
  min_capacity     = var.db_min_capacity
  
  # Security: Only allow traffic from within the VPC's IP range.
  allowed_cidr_blocks = [var.vpc_cidr]   
}

# A "data" source fetches information that already exists in AWS or is calculated 
# by the provider. Here, we fetch your unique AWS Account ID.
data "aws_caller_identity" "current" {}

# "locals" are like internal variables. They are useful for transforming data
# or creating strings that you'll reuse multiple times in this file.
locals {
  # S3 bucket names must be globally unique across all of AWS.
  # Appending the Account ID ensures yours won't collide with someone else's.
  bucket_name = "bedrock-kb-${data.aws_caller_identity.current.account_id}"
}

# This module sets up the S3 bucket where you will upload your PDF spec sheets.
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket = local.bucket_name
  acl    = "private"
  
  # force_destroy: Allows Terraform to delete the bucket even if it contains files.
  # USE WITH CAUTION in production!
  force_destroy = true

  # Ownership controls help prevent accidental public exposure of your data.
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  # Versioning keeps a history of your files, helpful if you accidentally overwrite a document.
  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # These four "block" settings are "Public Access Block" configurations.
  # They are the strongest way to ensure your private documents stay private.
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}
