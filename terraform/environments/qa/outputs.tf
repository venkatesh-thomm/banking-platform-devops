output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds.db_endpoint
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = module.rds.db_port
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = module.rds.security_group_id
}

output "external_secrets_role_arn" {
  description = "External Secrets IAM role ARN"
  value       = module.eks.external_secrets_role_arn
}

output "load_balancer_controller_role_arn" {
  description = "AWS Load Balancer Controller IAM role ARN"
  value       = module.load_balancer_controller.role_arn
}

output "load_balancer_controller_policy_arn" {
  description = "AWS Load Balancer Controller IAM policy ARN"
  value       = module.load_balancer_controller.policy_arn
}

# /* 
# output "acm_certificate_arn" {
#   description = "ACM certificate ARN"
#   value       = module.acm.certificate_arn
# }

# output "acm_domain_name" {
#   description = "ACM certificate domain name"
#   value       = module.acm.domain_name
# }

# output "acm_domain_validation_options" {
#   description = "ACM DNS validation records"
#   value       = module.acm.domain_validation_options
# } */


# output "waf_web_acl_arn" {
#   description = "WAF Web ACL ARN"
#   value       = module.waf.web_acl_arn
# }

# /* 
# output "cloudfront_distribution_id" {
#   description = "CloudFront distribution ID"
#   value       = module.cloudfront.distribution_id
# }

# output "cloudfront_domain_name" {
#   description = "CloudFront domain name"
#   value       = module.cloudfront.distribution_domain_name
# }

# output "cloudfront_arn" {
#   description = "CloudFront distribution ARN"
#   value       = module.cloudfront.distribution_arn
# }

#  */
# output "github_actions_role_arn" {
#   description = "GitHub Actions IAM role ARN"
#   value       = module.github_actions.role_arn
# }
