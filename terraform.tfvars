aws_region   = "ap-south-1"
cluster_name = "fashionassit"

vpc_id = "vpc-0c8ed77e28e92fefb"
private_subnet_ids = [
  "subnet-0e298ceb8b68ecc78",
  "subnet-099eb3166e0900346",
  "subnet-00e6626576fc24d03"
]

cluster_endpoint_private_access = false
cluster_endpoint_public_access  = true
public_access_cidrs             = ["0.0.0.0/0"]

instance_types = ["t3.medium"]
min_size       = 1
desired_size   = 1
max_size       = 2

# ECR values
aws_account_id = "583192270368"
ecr_repo_name  = "myapp"

# Use the SHA tag that exists in your ECR
image_tag      = "d5016a905f241d621d8ddb3d4f05e7b700037f44"

# Node role for attaching ECR pull policy
node_role_name = "default-eks-node-group-20250905063734841600000004"
