terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider configuration - supports both AWS and LocalStack
provider "aws" {
  region = var.aws_region

  # LocalStack configuration (when LOCAL_STACK_ENDPOINT is set)
  access_key                  = var.localstack_enabled ? "test" : var.aws_access_key
  secret_key                  = var.localstack_enabled ? "test" : var.aws_secret_key
  skip_credentials_validation = var.localstack_enabled
  skip_metadata_api_check     = var.localstack_enabled
  skip_requesting_account_id  = var.localstack_enabled

  endpoints {
    ec2 = var.localstack_enabled ? var.localstack_endpoint : null
    iam = var.localstack_enabled ? var.localstack_endpoint : null
    sts = var.localstack_enabled ? var.localstack_endpoint : null
  }
}

# Data source for AMI - with LocalStack compatibility
data "aws_ami" "ubuntu" {
  count       = var.localstack_enabled ? 0 : 1
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Use a fake AMI ID for LocalStack
locals {
  ami_id = var.localstack_enabled ? "ami-12345678" : data.aws_ami.ubuntu[0].id
}

# Key pair for EC2 instances
resource "aws_key_pair" "app_key" {
  key_name   = "${var.project_name}-key"
  public_key = var.public_key
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Private Subnet for Database
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "${var.project_name}-private-subnet"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway for Private Subnet
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.project_name}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Table for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Include security groups
module "security" {
  source = "./security"

  project_name = var.project_name
  vpc_id       = aws_vpc.main.id
}

# Include EC2 instances
module "ec2" {
  source = "./ec2"

  project_name          = var.project_name
  environment          = var.environment
  ami_id               = local.ami_id
  key_pair_name        = aws_key_pair.app_key.key_name
  public_subnet_id     = aws_subnet.public.id
  private_subnet_id    = aws_subnet.private.id
  web_security_group_id = module.security.web_server_sg_id
  db_security_group_id = module.security.database_sg_id
  instance_type_app    = var.instance_type_app
  instance_type_db     = var.instance_type_db
}

# Include EBS volumes
module "volumes" {
  source = "./volumes"

  project_name      = var.project_name
  environment      = var.environment
  ebs_volume_size  = var.ebs_volume_size
  availability_zone = aws_subnet.private.availability_zone
  database_instance_id = module.ec2.database_instance_id
}
