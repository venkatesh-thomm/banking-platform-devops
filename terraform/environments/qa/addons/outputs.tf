output "github_actions_role_arn" {
  description = "GitHub Actions IAM role ARN"
  value       = module.github_actions.role_arn
}


output "load_balancer_controller_role_arn" {
  description = "AWS Load Balancer Controller IAM role ARN"
  value       = module.load_balancer_controller.role_arn
}

output "load_balancer_controller_policy_arn" {
  description = "AWS Load Balancer Controller IAM policy ARN"
  value       = module.load_balancer_controller.policy_arn
}
