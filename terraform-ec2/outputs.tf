# Outputs for EC2 deployment
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "elastic_ip" {
  description = "Elastic IP address of the application"
  value       = aws_eip.app_server.public_ip
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_eip.app_server.public_ip}"
}

output "frontend_url" {
  description = "Frontend application URL"
  value       = "http://${aws_eip.app_server.public_ip}"
}

output "backend_api_url" {
  description = "Backend API URL"
  value       = "http://${aws_eip.app_server.public_ip}:17000"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_eip.app_server.public_ip}"
}
