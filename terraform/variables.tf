variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ani-app"
}

variable "public_key" {
  description = "Public key for EC2 instances"
  type        = string
}

variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  default     = ""
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  default     = ""
}

variable "localstack_enabled" {
  description = "Enable LocalStack for local testing"
  type        = bool
  default     = false
}

variable "localstack_endpoint" {
  description = "LocalStack endpoint URL"
  type        = string
  default     = "http://localhost:4566"
}

variable "instance_type_app" {
  description = "EC2 instance type for application server"
  type        = string
  default     = "t3.small"
}

variable "instance_type_db" {
  description = "EC2 instance type for database server"
  type        = string
  default     = "t3.micro"
}

variable "ebs_volume_size" {
  description = "Size of EBS volume for MongoDB data in GB"
  type        = number
  default     = 20
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}
