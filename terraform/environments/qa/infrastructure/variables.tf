variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "db_password" {
  type        = string
  description = "RDS database password"
  sensitive   = true
}

variable "zone_id" {
  description = "Route53 Hosted Zone ID for domain validation"
  type        = string
  default     = "Z0837378FXQAICHUIMDW"

}
