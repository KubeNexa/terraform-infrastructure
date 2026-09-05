# This module provisions ONLY the RDS instance itself - the security
# group, subnet group, and credentials. It deliberately does NOT create
# the four per-service logical databases/roles here: that requires the
# `postgresql` provider, and Terraform provider *configuration* belongs
# in the root module, not inside a child module, since a module's
# provider block can't cleanly depend on that same module's own
# resources being created first. See environments/dev/databases.tf for
# where shopstream_users/products/orders/payments and their scoped
# per-service roles actually get created, using this module's outputs.

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db"
  subnet_ids = var.private_subnet_ids

  tags = var.tags
}

resource "aws_security_group" "this" {
  name        = "${var.name}-rds"
  description = "Allow Postgres (5432) from inside the VPC only - never publicly accessible"
  vpc_id      = var.vpc_id

  ingress {
    description = "Postgres from within the VPC (EKS nodes)"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-rds" })
}

resource "random_password" "master" {
  length  = 32
  special = false # avoid characters that need escaping in a connection string / shell env var
}

resource "aws_secretsmanager_secret" "master" {
  name        = "${var.name}/rds/master-credentials"
  description = "RDS master credentials for the shared ${var.name} Postgres instance. Not used by any application directly - each service gets its own narrower credentials (see environments/dev/databases.tf), this is only for administrative access."

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "master" {
  secret_id = aws_secretsmanager_secret.master.id
  secret_string = jsonencode({
    username = "shopstream_admin"
    password = random_password.master.result
    host     = aws_db_instance.this.address
    port     = 5432
  })
}

resource "aws_db_instance" "this" {
  identifier     = "${var.name}-postgres"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage_gb
  max_allocated_storage = var.allocated_storage_gb * 3 # storage autoscaling ceiling - avoids a manual resize later for modest growth

  username = "shopstream_admin"
  password = random_password.master.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_days
  storage_encrypted       = true

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-postgres-final"

  # This instance's own default database (never used directly by any
  # service - each service's actual database is created separately,
  # see environments/dev/databases.tf).
  db_name = "postgres"

  tags = var.tags
}
