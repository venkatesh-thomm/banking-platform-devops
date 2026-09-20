output "role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = aws_iam_role.this.arn
}

output "policy_arn" {
  description = "IAM policy ARN for AWS Load Balancer Controller"
  value       = aws_iam_policy.this.arn
}
