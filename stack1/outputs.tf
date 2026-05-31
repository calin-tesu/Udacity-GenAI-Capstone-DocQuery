output "db_endpoint" {
  description = "The writer endpoint for the Aurora Serverless cluster."
  value = module.aurora_serverless.cluster_endpoint
}

output "db_reader_endpoint" {
  description = "The reader endpoint for the Aurora Serverless cluster."
  value = module.aurora_serverless.cluster_reader_endpoint
}

output "vpc_id" {
  description = "The ID of the VPC."
  value = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value = module.vpc.public_subnets
}

output "aurora_endpoint" {
  description = "The cluster endpoint for the Aurora Serverless database."
  value = module.aurora_serverless.cluster_endpoint
}

output "aurora_arn" {
  description = "The ARN of the Aurora Serverless cluster."
  value = module.aurora_serverless.database_arn
}

output "rds_secret_arn" {
  description = "The ARN of the Secrets Manager secret for the RDS database credentials."
  value = module.aurora_serverless.database_secretsmanager_secret_arn
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket used for the Bedrock Knowledge Base."
  value = module.s3_bucket.s3_bucket_arn
}

output "db_name" {
  description = "The name of the database created in stack1."
  value       = var.db_name
}

output "db_username" {
  description = "The master username for the database."
  value       = var.db_username
}

output "aurora_table_name" {
  description = "The name of the table used for Bedrock embeddings."
  value       = var.aurora_table_name
}