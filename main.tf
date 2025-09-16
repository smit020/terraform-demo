module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.33"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.public_access_cidrs

  eks_managed_node_groups = {
    default = {
      min_size       = var.min_size
      desired_size   = var.desired_size
      max_size       = var.max_size
      instance_types = var.instance_types
      subnet_ids     = var.private_subnet_ids
    }
  }

  enable_cluster_creator_admin_permissions = true
  tags                                     = var.tags
}

resource "aws_ecr_repository" "app" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  tags = merge(var.tags, { Name = var.ecr_repo_name })
}

data "aws_iam_role" "node_role_lookup" {
  count = var.node_role_name != "" ? 1 : 0
  name  = var.node_role_name
}

resource "aws_iam_role_policy_attachment" "node_ecr_read" {
  count     = var.node_role_name != "" ? 1 : 0
  role      = data.aws_iam_role.node_role_lookup[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
