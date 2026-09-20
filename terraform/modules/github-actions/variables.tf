variable "github_org" {
  type        = string
  description = "GitHub username or organization"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
}

variable "ecr_repository_arn" {
  type        = string
  description = "ECR repository ARN"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "github_org_id" {
  type        = string
  description = "GitHub owner ID"
}

variable "github_repo_id" {
  type        = string
  description = "GitHub repository ID"
}
