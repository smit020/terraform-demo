variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "cluster_name" {
  type    = string
  default = "fashionassit"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "min_size" {
  type    = number
  default = 1
}

variable "desired_size" {
  type    = number
  default = 0
}

variable "max_size" {
  type    = number
  default = 2
}

variable "cluster_endpoint_private_access" {
  type    = bool
  default = false
}

variable "cluster_endpoint_public_access" {
  type    = bool
  default = true
}

variable "public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "tags" {
  type    = map(string)
  default = { Managed = "terraform" }
}

# --- ECR / image variables ---
variable "aws_account_id" {
  description = "AWS account ID used for ECR URI"
  type        = string
}

variable "ecr_repo_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "myapp"
}

variable "image_tag" {
  description = "Image tag used when pushing (example: v1.0.0 or sha)"
  type        = string
  default     = "v1.0.0"
}

# Kubernetes app variables
variable "namespace" {
  type    = string
  default = "default"
}

variable "app_name" {
  type    = string
  default = "myapp"
}

variable "image" {
  type    = string
  default = "hashicorp/http-echo:0.2.3"
}

variable "replicas" {
  type    = number
  default = 1
}

variable "container_port" {
  type    = number
  default = 5678
}

variable "service_port" {
  type    = number
  default = 80
}

# optional: IAM instance role name for EKS worker nodes
variable "node_role_name" {
  description = "If set, attach ECR read policy to this IAM role (instance role name). Leave empty to skip."
  type        = string
  default     = ""
}
