# Variables for EBS module
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "ebs_volume_size" {
  description = "Size of EBS volume in GB"
  type        = number
}

variable "availability_zone" {
  description = "Availability zone for EBS volume"
  type        = string
}

variable "database_instance_id" {
  description = "Database instance ID to attach volume to"
  type        = string
}

# EBS Volume for MongoDB data
resource "aws_ebs_volume" "mongodb_data" {
  availability_zone = var.availability_zone
  size              = var.ebs_volume_size
  type              = "gp3"
  encrypted         = true

  tags = {
    Name = "${var.project_name}-mongodb-data"
    Environment = var.environment
  }
}

# EBS Volume attachment to database instance
resource "aws_volume_attachment" "mongodb_data_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.mongodb_data.id
  instance_id = var.database_instance_id
}

# Outputs
output "ebs_volume_id" {
  description = "ID of the EBS volume"
  value       = aws_ebs_volume.mongodb_data.id
}

output "ebs_volume_arn" {
  description = "ARN of the EBS volume"
  value       = aws_ebs_volume.mongodb_data.arn
}
