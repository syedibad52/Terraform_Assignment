output "flask_backend_private_ip" {
  description = "Private IP of Flask backend"
  value       = aws_instance.flask_backend.private_ip
}

output "flask_backend_public_ip" {
  description = "Public IP of Flask backend"
  value       = aws_instance.flask_backend.public_ip
}

output "express_frontend_public_ip" {
  description = "Public IP of Express frontend"
  value       = aws_instance.express_frontend.public_ip
}

output "express_app_url" {
  description = "URL to access Express application"
  value       = "http://${aws_instance.express_frontend.public_ip}:3000"
}

output "flask_api_url" {
  description = "URL to access Flask API"
  value       = "http://${aws_instance.flask_backend.public_ip}:5000"
}
