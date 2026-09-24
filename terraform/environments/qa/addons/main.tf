
module "load_balancer_controller" {
  source = "../../../modules/eks/load-balancer-controller"

  cluster_name = data.terraform_remote_state.infrastructure.outputs.eks_cluster_name
  environment  = "qa"

  vpc_id = data.terraform_remote_state.infrastructure.outputs.vpc_id

  oidc_provider_arn = data.terraform_remote_state.infrastructure.outputs.eks_oidc_provider_arn

  oidc_provider_url = replace(
    data.terraform_remote_state.infrastructure.outputs.eks_oidc_provider_url,
    "https://",
    ""
  )
}


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

  ecr_repository_arn = data.terraform_remote_state.infrastructure.outputs.ecr_repository_arn

  environment = "qa"
}


module "argocd" {
  source = "../../../modules/argocd"

  namespace     = "argocd"
  chart_version = "9.1.2"

}


module "external_secrets" {
  source = "../../../modules/external-secrets"

  iam_role_arn = data.terraform_remote_state.infrastructure.outputs.external_secrets_role_arn



}


module "metrics_server" {
  source = "../../../modules/metrics-server"


}
