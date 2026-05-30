variable "aws_region" {
  description = "The AWS region to deploy the bootstrap resources."
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "A prefix for naming resources to ensure uniqueness."
  type        = string
  default     = "docquery"
}

variable "environment" {
  description = "The deployment environment (e.g., dev, prod)."
  type        = string
  default     = "dev"
}