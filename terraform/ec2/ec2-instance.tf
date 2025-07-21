# Variables for EC2 module
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "key_pair_name" {
  description = "Key pair name for EC2 instances"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for web server"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for database"
  type        = string
}

variable "web_security_group_id" {
  description = "Security group ID for web server"
  type        = string
}

variable "db_security_group_id" {
  description = "Security group ID for database"
  type        = string
}

variable "instance_type_app" {
  description = "Instance type for application server"
  type        = string
}

variable "instance_type_db" {
  description = "Instance type for database server"
  type        = string
}

# Web Server Instance (Nginx + React + Node.js)
resource "aws_instance" "web_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type_app
  key_name               = var.key_pair_name
  vpc_security_group_ids = [var.web_security_group_id]
  subnet_id              = var.public_subnet_id

  user_data = templatefile("${path.module}/../scripts/provision-web.sh", {
    mongodb_host = aws_instance.database.private_ip
    environment  = var.environment
  })

  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = var.environment
    Type        = "WebServer"
  }

  depends_on = [aws_instance.database]
}

# Database Server Instance (MongoDB)
resource "aws_instance" "database" {
  ami                    = var.ami_id
  instance_type          = var.instance_type_db
  key_name               = var.key_pair_name
  vpc_security_group_ids = [var.db_security_group_id]
  subnet_id              = var.private_subnet_id

  user_data = templatefile("${path.module}/../scripts/provision-db.sh", {
    ebs_device   = "/dev/sdf"
    environment  = var.environment
  })

  tags = {
    Name        = "${var.project_name}-database"
    Environment = var.environment
    Type        = "Database"
  }
}

# Outputs
output "web_server_instance_id" {
  description = "ID of the web server instance"
  value       = aws_instance.web_server.id
}

output "database_instance_id" {
  description = "ID of the database instance"
  value       = aws_instance.database.id
}

output "web_server_public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web_server.public_ip
}

output "web_server_private_ip" {
  description = "Private IP of the web server"
  value       = aws_instance.web_server.private_ip
}

output "database_private_ip" {
  description = "Private IP of the database server"
  value       = aws_instance.database.private_ip
}
