output "github_actions_role_arn" {
  description = "GitHub Actions IAM role ARN"
  value       = module.github_actions.role_arn
}
