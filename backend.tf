terraform {
  backend "s3" {
    bucket         = "fashionassit-state"
    key            = "eks-private/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
