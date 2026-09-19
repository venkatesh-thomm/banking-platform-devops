variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "db_password" {
  type        = string
  description = "RDS database password"
  sensitive   = true
}

