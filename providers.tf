terraform {
  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 5.0" }
    kubernetes = { source = "hashicorp/kubernetes" }
    helm       = { source = "hashicorp/helm" }
    random     = { source = "hashicorp/random" }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  config_path    = "C:\\Users\\admin\\.kube\\config"
  config_context = "arn:aws:eks:${var.aws_region}:${var.aws_account_id}:cluster/${var.cluster_name}"
}

provider "helm" {
  kubernetes = {
    config_path    = "C:\\Users\\admin\\.kube\\config"
    config_context = "arn:aws:eks:${var.aws_region}:${var.aws_account_id}:cluster/${var.cluster_name}"
  }
}
