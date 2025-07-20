# Terraform configuration for LocalStack AWS simulation
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3             = "http://localhost:4566"
    ecs            = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    iam            = "http://localhost:4566"
    logs           = "http://localhost:4566"
    elbv2          = "http://localhost:4566"
    ecr            = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    servicediscovery = "http://localhost:4566"
  }
}
