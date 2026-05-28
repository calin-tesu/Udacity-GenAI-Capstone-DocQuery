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

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "vpc_azs" {
  type    = list(string)
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "db_name" {
  type    = string
  default = "myapp"
}

variable "db_username" {
  type    = string
  default = "dbadmin"
}

variable "db_engine_version" {
  type    = string
  default = "16.4"
}

variable "db_max_capacity" {
  type    = number
  default = 1.0
}

variable "db_min_capacity" {
  type    = number
  default = 0.5
}