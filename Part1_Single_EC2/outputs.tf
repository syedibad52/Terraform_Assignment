output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.single_ec2.public_ip
}

output "express_frontend_url" {
  description = "URL to access Express frontend"
  value       = "http://${aws_instance.single_ec2.public_ip}:3000"
}

output "flask_backend_url" {
  description = "URL to access Flask backend"
  value       = "http://${aws_instance.single_ec2.public_ip}:5000"
}
