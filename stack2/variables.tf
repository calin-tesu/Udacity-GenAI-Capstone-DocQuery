variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "project_name" {
  type    = string
  default = "bedrock-poc"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "knowledge_base_name" {
  type    = string
  default = "my-bedrock-kb"
}

variable "knowledge_base_description" {
  type    = string
  default = "Knowledge base connected to Aurora Serverless database"
}
