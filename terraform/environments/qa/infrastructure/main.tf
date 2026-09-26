module "vpc" {
  source = "../../../modules/vpc"

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
  source = "../../../modules/eks"

  cluster_name       = "banking-qa-eks"
  kubernetes_version = "1.34"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  environment        = "qa"
  depends_on         = [module.vpc]
}


module "ecr" {
  source = "../../../modules/ecr"

  repository_name = "banking-qa-backend"
  environment     = "qa"
  depends_on      = [module.vpc]
}


module "rds" {
  source = "../../../modules/rds"

  db_name     = "banking"
  db_username = "banking_user"
  db_password = var.db_password

  db_instance_class = "db.t3.micro"

  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id

  environment = "qa"
  depends_on  = [module.vpc]
}



module "acm" {
  source = "../../../modules/acm"

  domain_name = "*.venkatesh.live"
  environment = "qa"
  zone_id     = var.zone_id
}





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
