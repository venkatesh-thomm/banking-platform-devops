variable "name" {
  type        = string
  description = "CloudFront distribution name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "alb_dns_name" {
  type        = string
  description = "ALB DNS name used as CloudFront origin"
}

variable "web_acl_arn" {
  type        = string
  description = "WAF Web ACL ARN"
}
