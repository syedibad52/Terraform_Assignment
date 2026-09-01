variable "aws_region" {
  description = "AWS Region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "flask_container_port" {
  description = "Port exposed by Flask container"
  type        = number
  default     = 5000
}

variable "express_container_port" {
  description = "Port exposed by Express container"
  type        = number
  default     = 3000
}
