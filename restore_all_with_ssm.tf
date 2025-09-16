########################
# restore_all_with_ssm.tf
########################

# -------- Variables expected --------
# var.app_name
# var.aws_region
# var.vpc_id
# var.public_subnet_id
# var.restore_instance_type
# var.restore_sql_path
# var.db_name
# var.db_master_password
# tags map in var.tags
# Optionally: var.restore_s3_bucket ("" to auto-generate)

# Unique suffix for S3 bucket
resource "random_id" "restore_suffix" {
  byte_length = 6
}

locals {
  app_name_sanitized  = lower(replace(var.app_name, "_", "-"))
  restore_bucket_name = var.restore_s3_bucket != "" ? lower(var.restore_s3_bucket) : "${local.app_name_sanitized}-${var.aws_region}-restore-${random_id.restore_suffix.hex}"
}

########################
# S3 bucket for dump (ACLs disabled)
########################
resource "aws_s3_bucket" "restore_bucket" {
  bucket        = local.restore_bucket_name
  force_destroy = true
  tags          = var.tags
}

# Enforce Object Ownership = BucketOwnerEnforced (disables ACLs)
resource "aws_s3_bucket_ownership_controls" "restore_owner" {
  bucket = aws_s3_bucket.restore_bucket.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "restore_block" {
  bucket                  = aws_s3_bucket.restore_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

########################
# SQL dump object (no ACL set)
########################
resource "aws_s3_object" "dump" {
  bucket = aws_s3_bucket.restore_bucket.id
  key    = "dump.sql"
  source = var.restore_sql_path
  etag   = filemd5(var.restore_sql_path)
}

########################
# AMI lookup (Amazon Linux 2)
########################
data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

########################
# Restore EC2 security group (egress only)
########################
resource "aws_security_group" "restore_ec2" {
  name_prefix = "${var.app_name}-restore-ec2-sg-"
  description = "Managed SG for restore EC2 (egress only)"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle { create_before_destroy = true }

  tags = merge(var.tags, { Name = "${var.app_name}-restore-ec2-sg" })
}

########################
# EC2 Instance (restore host)
########################
resource "aws_instance" "restore" {
  ami                         = data.aws_ami.amzn2.id
  instance_type               = var.restore_instance_type
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.restore_ec2.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = merge(var.tags, { Name = "${var.app_name}-restore-ec2" })
}

########################
# IAM for SSM + S3 read
########################
resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.app_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "s3_read" {
  name = "${var.app_name}-s3-read"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject"],
        Resource = ["${aws_s3_bucket.restore_bucket.arn}/*"]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.app_name}-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

########################
# SSM Document (restore workflow) – Postgres 17 client, filter + clean
########################
resource "aws_ssm_document" "restore_cmd" {
  name          = "${var.app_name}-restore-cmd"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Restore RDS from S3 dump using Postgres 17 client. Filter SET transaction_timeout (PG17-only) and drop existing objects before recreate (--clean --if-exists).",
    mainSteps = [
      {
        action = "aws:runShellScript",
        name   = "restore",
        inputs = {
          runCommand = [
            "#!/bin/bash",
            "set -euo pipefail",
            "echo 'Starting restore SSM document...'",

            "# Ensure Docker and tools",
            "yum update -y || true",
            "if command -v amazon-linux-extras >/dev/null 2>&1; then amazon-linux-extras install -y docker || true; fi",
            "yum install -y docker awscli gzip file || true",
            "systemctl enable --now docker || true",

            "# Download dump from S3",
            "SRC_S3=\"s3://${aws_s3_bucket.restore_bucket.bucket}/${aws_s3_object.dump.key}\"",
            "INFILE=\"/tmp/dump.in\"",
            "OUTFILE=\"/tmp/dump.sql\"",
            "echo \"Downloading $${SRC_S3} to $${INFILE}\"",
            "aws s3 cp \"$${SRC_S3}\" \"$${INFILE}\" --region ${var.aws_region}",
            "ls -lh \"$${INFILE}\" || true",

            "# Normalize to /tmp/dump.sql (handle gzip if needed)",
            "if file -b \"$${INFILE}\" | grep -qi 'gzip compressed'; then",
            "  gunzip -c \"$${INFILE}\" > \"$${OUTFILE}\"",
            "else",
            "  cp -f \"$${INFILE}\" \"$${OUTFILE}\"",
            "fi",
            "ls -lh \"$${OUTFILE}\" || true",
            "DESC=$(file -b \"$${OUTFILE}\" || true)",
            "echo \"Detected dump type: $${DESC}\"",

            "# Connection vars",
            "export PGPASSWORD='${var.db_master_password}'",
            "HOST='${aws_db_instance.pg.address}'",
            "PORT='${aws_db_instance.pg.port}'",
            "USER='${aws_db_instance.pg.username}'",
            "DB='${var.db_name}'",

            "# Wait for RDS to be ready using Postgres 17 client",
            "echo 'Waiting for RDS to accept connections...';",
            "for i in $(seq 1 120); do",
            "  if docker run --rm postgres:17 bash -lc \"export PGPASSWORD='$${PGPASSWORD}'; pg_isready -h $${HOST} -p $${PORT} -U $${USER} -d $${DB}\" >/dev/null 2>&1; then",
            "    echo 'RDS is ready'; break;",
            "  fi; echo \"Waiting... ($$i)\"; sleep 5;",
            "done",

            "# Helpers using Postgres 17 client (needed for v1.16 archive)",
            "# Filter out SET transaction_timeout (PG17-only) and drop existing objects before recreate",
            "restore_custom() {",
            "  docker run --rm -v /tmp:/tmp -e PGPASSWORD=\"$${PGPASSWORD}\" postgres:17 bash -lc \"pg_restore --clean --if-exists --no-owner --no-privileges --verbose -f - /tmp/dump.sql | sed -E '/^SET[[:space:]]+transaction_timeout[[:space:]]*=/d' | psql -h $${HOST} -p $${PORT} -U $${USER} -d $${DB} --set ON_ERROR_STOP=on\"",
            "}",
            "restore_plain() {",
            "  docker run --rm -v /tmp:/tmp -e PGPASSWORD=\"$${PGPASSWORD}\" postgres:17 bash -lc \"psql -h $${HOST} -p $${PORT} -U $${USER} -d $${DB} -f /tmp/dump.sql --set ON_ERROR_STOP=on\"",
            "}",

            "# Choose restore path",
            "if echo \"$${DESC}\" | grep -qi 'PostgreSQL custom'; then",
            "  echo 'Custom archive detected; using pg_restore (Postgres 17) with transaction_timeout filtered and clean mode.';",
            "  if ! restore_custom; then",
            "    echo 'pg_restore pipeline failed; attempting schema permission grant and retry...';",
            "    docker run --rm -e PGPASSWORD=\"$${PGPASSWORD}\" postgres:17 psql -h \"$${HOST}\" -p \"$${PORT}\" -U \"$${USER}\" -d \"$${DB}\" -c \"GRANT USAGE, CREATE ON SCHEMA public TO $${USER};\" || true",
            "    restore_custom",
            "  fi",
            "else",
            "  echo 'Plain SQL detected; using psql (Postgres 17).';",
            "  restore_plain",
            "fi",

            "echo 'Restore finished.'"
          ]
        }
      }
    ]
  })
}

########################
# SSM Association (waits until Success)
########################
resource "aws_ssm_association" "restore_assoc" {
  name             = aws_ssm_document.restore_cmd.name
  association_name = "restore-association"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.restore.id]
  }

  depends_on = [
    aws_s3_object.dump,
    aws_s3_bucket.restore_bucket,
    aws_s3_bucket_ownership_controls.restore_owner,
    aws_s3_bucket_public_access_block.restore_block,
    aws_instance.restore,
    aws_ssm_document.restore_cmd
  ]

  # Wait for the association status to be Success
  wait_for_success_timeout_seconds = 7200
}
