provider "kubernetes" {
  config_path    = "C:\\Users\\admin\\.kube\\config"
  config_context = "arn:aws:eks:ap-south-1:583192270368:cluster/fashionassit"
}

provider "helm" {
  kubernetes = {
    config_path    = "C:\\Users\\admin\\.kube\\config"
    config_context = "arn:aws:eks:ap-south-1:583192270368:cluster/fashionassit"
  }
}
