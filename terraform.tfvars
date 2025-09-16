aws_region   = "ap-south-1"
cluster_name = "fashionassit"

vpc_id = "vpc-0c8ed77e28e92fefb"
private_subnet_ids = [
  "subnet-0e298ceb8b68ecc78",
  "subnet-099eb3166e0900346",
  "subnet-00e6626576fc24d03"
]

public_access_cidrs = ["0.0.0.0/0"]

aws_account_id = "583192270368"
ecr_repo_name  = "myapp"
image_tag      = "d5016a905f241d621d8ddb3d4f05e7b700037f44"

namespace      = "default"
app_name       = "myapp"
replicas       = 1
container_port = 5000
service_port   = 80

# New target RDS
db_name            = "myappdb"
db_master_password = "8A9ey0A5znX0"

# Public subnet for the temporary EC2 that will run the restore
public_subnet_id = "subnet-02be666169e9a74ab"

# Optional: override if your dump is not at ../db/dump.sql
# restore_sql_path  = "../db/dump.sql"
# Optional: override to enforce a fixed bucket name
# restore_s3_bucket = "myapp-restore-fixed-name"
