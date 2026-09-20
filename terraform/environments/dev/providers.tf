terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster" "qa" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "qa" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.qa.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.qa.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.qa.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.qa.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.qa.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.qa.token
  }
}
