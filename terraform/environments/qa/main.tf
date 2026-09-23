module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr = "10.1.0.0/16"

  public_subnet_cidrs = [
    "10.1.1.0/24",
    "10.1.2.0/24"
  ]

  private_subnet_cidrs = [
    "10.1.10.0/24",
    "10.1.11.0/24"
  ]

  environment = "qa"
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = "banking-qa-eks"
  kubernetes_version = "1.34"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  environment        = "qa"
  depends_on         = [module.vpc]
}


module "ecr" {
  source = "../../modules/ecr"

  repository_name = "banking-qa-backend"
  environment     = "qa"
  depends_on      = [module.vpc]
}


module "rds" {
  source = "../../modules/rds"

  db_name     = "banking"
  db_username = "banking_user"
  db_password = var.db_password

  db_instance_class = "db.t3.micro"

  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id

  environment = "qa"
  depends_on  = [module.vpc]
}


module "load_balancer_controller" {
  source = "../../modules/eks/load-balancer-controller"

  cluster_name = module.eks.cluster_name
  environment  = "qa"

  vpc_id = module.vpc.vpc_id

  oidc_provider_arn = module.eks.oidc_provider_arn

  oidc_provider_url = replace(
    module.eks.oidc_provider_url,
    "https://",
    ""
  )
  depends_on = [module.eks]
}

# /* 
# module "acm" {
#   source = "../../modules/acm"

#   domain_name = "api.venkatesh.fun"
#   environment = "qa"
# } */


# module "waf" {
#   source = "../../modules/waf"

#   name        = "banking-qa-waf"
#   environment = "qa"
# }
# /* 
# module "cloudfront" {
#   source = "../../modules/cloudfront"

#   name        = "banking-qa-cloudfront"
#   environment = "qa"

#   alb_dns_name = "k8s-default-bankingb-8180975c90-604770014.us-east-1.elb.amazonaws.com"

#   web_acl_arn = module.waf.web_acl_arn
# } */

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
  source = "../../modules/github-actions"

  github_org  = "venkatesh-thomm"
  github_repo = "banking-platform-app"

  github_org_id  = "46835167"
  github_repo_id = "1378140036"

  ecr_repository_arn = module.ecr.repository_arn

  environment = "qa"
}


module "argocd" {
  source = "../../modules/argocd"

  namespace     = "argocd"
  chart_version = "9.1.2"
  depends_on = [
    module.eks,
    module.external_secrets,
    module.load_balancer_controller
  ]
}


module "external_secrets" {
  source = "../../modules/external-secrets"

  iam_role_arn = module.eks.external_secrets_role_arn

  depends_on = [
    module.eks
  ]

}
