module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr    = "10.0.0.0/16"
  environment = "dev"
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = "banking-dev-eks"
  kubernetes_version = "1.34"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}


module "ecr" {
  source = "../../modules/ecr"

  repository_name = "banking-dev-backend"
}


module "rds" {
  source = "../../modules/rds"

  db_name     = "banking"
  db_username = "banking_user"
  db_password = var.db_password

  db_instance_class = "db.t3.micro"

  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id

  environment = "dev"
}
