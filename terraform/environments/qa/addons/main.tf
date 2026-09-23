
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Project     = "banking-platform"
    Environment = "qa"
  }
}


module "github_actions" {
  source = "../../../modules/github-actions"

  github_org  = "venkatesh-thomm"
  github_repo = "banking-platform-app"

  github_org_id  = "46835167"
  github_repo_id = "1378140036"

  ecr_repository_arn = module.ecr.repository_arn

  environment = "qa"
}


module "argocd" {
  source = "../../../modules/argocd"

  namespace     = "argocd"
  chart_version = "9.1.2"
  depends_on = [
    module.eks,
    module.external_secrets,
    module.load_balancer_controller
  ]
}


module "external_secrets" {
  source = "../../../modules/external-secrets"

  iam_role_arn = module.eks.external_secrets_role_arn

  depends_on = [
    module.eks
  ]

}


module "metrics_server" {
  source = "../../../modules/metrics-server"

  depends_on = [
    module.eks
  ]
}
