output "web_server_public_ip" {
  description = "Public IP address of the web server"
  value       = module.ec2.web_server_public_ip
}

output "web_server_public_dns" {
  description = "Public DNS name of the web server"
  value       = "ec2-${replace(module.ec2.web_server_public_ip, ".", "-")}.${var.aws_region}.compute.amazonaws.com"
}

output "database_private_ip" {
  description = "Private IP address of the database server"
  value       = module.ec2.database_private_ip
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${module.ec2.web_server_public_ip}"
}

output "ssh_command_web" {
  description = "SSH command to connect to web server"
  value       = "ssh -i ~/.ssh/your-key.pem ubuntu@${module.ec2.web_server_public_ip}"
}

output "ssh_command_db" {
  description = "SSH command to connect to database server (via bastion)"
  value       = "ssh -i ~/.ssh/your-key.pem -o ProxyJump=ubuntu@${module.ec2.web_server_public_ip} ubuntu@${module.ec2.database_private_ip}"
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "ebs_volume_id" {
  description = "ID of the MongoDB EBS volume"
  value       = module.volumes.ebs_volume_id
}
