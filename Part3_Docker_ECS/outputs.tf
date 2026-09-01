output "ecr_flask_repository_url" {
  description = "ECR Repository URL for Flask backend image"
  value       = aws_ecr_repository.flask.repository_url
}

output "ecr_express_repository_url" {
  description = "ECR Repository URL for Express frontend image"
  value       = aws_ecr_repository.express.repository_url
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main_alb.dns_name
}

output "express_frontend_url" {
  description = "Public URL to access Express frontend via ALB"
  value       = "http://${aws_lb.main_alb.dns_name}"
}

output "flask_backend_url" {
  description = "Public URL to access Flask backend API via ALB"
  value       = "http://${aws_lb.main_alb.dns_name}:5000"
}
