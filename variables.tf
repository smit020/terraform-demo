# --- Core ---
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
  default = 1
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
  description = "Image tag used"
  type        = string
  default     = "d5016a905f241d621d8ddb3d4f05e7b700037f44"
}

# Optional: IAM instance role for node group
variable "node_role_name" {
  description = "EKS worker node instance role name (empty to skip)"
  type        = string
  default     = ""
}

# --- Kubernetes app variables ---
variable "namespace" {
  type    = string
  default = "default"
}

variable "app_name" {
  type    = string
  default = "myapp"
}

variable "replicas" {
  type    = number
  default = 1
}

variable "container_port" {
  type    = number
  default = 5000
}

variable "service_port" {
  type    = number
  default = 80
}

# --- New target RDS ---
variable "db_name" {
  description = "Name for the new (target) database"
  type        = string
  default     = "myappdb"
}

variable "db_master_password" {
  description = "Master password for new RDS"
  type        = string
  sensitive   = true
}

# --- Automatic restore configuration ---
variable "run_restore" {
  description = "Whether to run the SQL restore after RDS creation (true/false)"
  type        = bool
  default     = true
}

variable "restore_sql_path" {
  description = "Path to SQL file to restore (relative to repo root). Example: ../db/dump.sql from terraform module."
  type        = string
  default     = "../db/dump.sql"
}


# --- New variables for EC2/SSM restore ---
variable "public_subnet_id" {
  description = "Public subnet id where the temporary EC2 will be launched"
  type        = string
}

variable "restore_instance_type" {
  description = "Instance type for restore machine"
  type        = string
  default     = "t3.micro"
}

variable "restore_s3_bucket" {
  description = "Optional S3 bucket name for the SQL dump (leave empty to auto-generate)"
  type        = string
  default     = ""
}
