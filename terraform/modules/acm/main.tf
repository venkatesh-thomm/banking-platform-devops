resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.venkatesh.live"]
  validation_method         = "DNS"

  tags = {
    Name        = "venkatesh-live"
    Environment = var.environment
    Project     = "banking-platform"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true

  name    = each.value.name
  records = [each.value.record]
  type    = each.value.type
  ttl     = 60

  zone_id = var.zone_id
}


resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn

  validation_record_fqdns = [
    for record in aws_route53_record.validation : record.fqdn
  ]

  depends_on = [
    aws_route53_record.validation
  ]
}
