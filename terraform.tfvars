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
image_tag      = "v1.0.0"

# Optional: after you push image to ECR, you can set this to make Terraform update the k8s Deployment:
# image = "583192270368.dkr.ecr.ap-south-1.amazonaws.com/myapp:v1.0.0"

# Node role for attaching ECR pull policy
node_role_name = "default-eks-node-group-20250905063734841600000004"
