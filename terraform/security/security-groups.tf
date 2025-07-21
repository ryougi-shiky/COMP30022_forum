# Variables for security module
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

# Security Group for Web Server (Nginx + Node.js + React)
resource "aws_security_group" "web_server" {
  name        = "${var.project_name}-web-server-sg"
  description = "Security group for web server"
  vpc_id      = var.vpc_id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Consider restricting this to your IP
  }

  # Backend API port (for development)
  ingress {
    from_port   = 17000
    to_port     = 17000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Only from VPC
  }

  # Frontend dev port (for development)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Only from VPC
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-server-sg"
  }
}

# Security Group for Database Server (MongoDB)
resource "aws_security_group" "database" {
  name        = "${var.project_name}-database-sg"
  description = "Security group for MongoDB database"
  vpc_id      = var.vpc_id

  # MongoDB access only from web server
  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.web_server.id]
  }

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Consider restricting this to your IP
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-database-sg"
  }
}

# Outputs for security groups
output "web_server_sg_id" {
  description = "ID of the web server security group"
  value       = aws_security_group.web_server.id
}

output "database_sg_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}
