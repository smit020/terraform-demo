resource "aws_security_group" "rds_sg" {
  name        = "${var.app_name}-rds-sg"
  vpc_id      = var.vpc_id
  description = "Managed by Terraform"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.app_name}-rds-sg" })
}

resource "aws_db_subnet_group" "db_subnets" {
  name       = "${var.app_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = { Name = "${var.app_name}-db-subnet-group" }
}

resource "aws_db_instance" "pg" {
  identifier        = "${var.app_name}-db-target"
  engine            = "postgres"
  engine_version    = "16.4"
  instance_class    = "db.t3.medium"
  allocated_storage = 20

  db_name  = var.db_name
  username = "masteruser"
  password = var.db_master_password

  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  skip_final_snapshot = true
  publicly_accessible = false
  apply_immediately   = true

  tags = merge(var.tags, { Name = "${var.app_name}-rds-target" })
}

locals {
  db_master_user = aws_db_instance.pg.username
  db_master_pass = var.db_master_password
  db_endpoint    = aws_db_instance.pg.address
  db_port        = aws_db_instance.pg.port
  db_name_local  = var.db_name
  db_url_master = format("postgresql://%s:%s@%s:%d/%s",
    local.db_master_user,
    local.db_master_pass,
    local.db_endpoint,
    local.db_port,
    local.db_name_local
  )
}

resource "kubernetes_secret" "db" {
  metadata {
    name      = "${var.app_name}-db-secret"
    namespace = var.namespace
  }
  data = {
    DATABASE_URL = base64encode(local.db_url_master)
    DB_USER      = base64encode(local.db_master_user)
    DB_PASSWORD  = base64encode(local.db_master_pass)
  }
  type = "Opaque"
}
