resource "aws_acm_certificate" "this" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Name        = var.domain_name
    Environment = var.environment
    Project     = "banking-platform"
  }

  lifecycle {
    create_before_destroy = true
  }
}
