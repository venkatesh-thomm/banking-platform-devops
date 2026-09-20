output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.this.arn
}

output "domain_name" {
  description = "Certificate domain name"
  value       = aws_acm_certificate.this.domain_name
}

output "domain_validation_options" {
  description = "ACM DNS validation records"
  value       = aws_acm_certificate.this.domain_validation_options
}
