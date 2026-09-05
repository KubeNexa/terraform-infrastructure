# DocumentDB is the MongoDB-compatible managed service AWS actually
# offers (there is no managed "real" MongoDB on AWS) - notification-
# service connects to this with its existing MONGO_URI-shaped
# connection string, same as it would to a real MongoDB Atlas cluster.
# Unlike RDS's four logical Postgres databases sharing one instance,
# this is its own dedicated cluster - notification-service is the only
# consumer, so there's no multi-tenant database to split.

resource "aws_docdb_subnet_group" "this" {
  name       = "${var.name}-docdb"
  subnet_ids = var.private_subnet_ids

  tags = var.tags
}

resource "aws_security_group" "this" {
  name        = "${var.name}-docdb"
  description = "Allow MongoDB wire protocol (27017) from inside the VPC only"
  vpc_id      = var.vpc_id

  ingress {
    description = "DocumentDB from within the VPC (EKS nodes)"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-docdb" })
}

resource "random_password" "master" {
  length  = 32
  special = false
}

resource "aws_docdb_cluster" "this" {
  cluster_identifier = "${var.name}-docdb"
  engine             = "docdb"
  engine_version     = var.engine_version

  master_username = "shopstream_admin"
  master_password = random_password.master.result

  db_subnet_group_name   = aws_docdb_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  storage_encrypted         = true
  backup_retention_period   = var.backup_retention_days
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-docdb-final"

  tags = var.tags
}

resource "aws_docdb_cluster_instance" "this" {
  count = var.instance_count

  identifier         = "${var.name}-docdb-${count.index}"
  cluster_identifier = aws_docdb_cluster.this.id
  instance_class     = var.instance_class

  tags = var.tags
}

resource "aws_secretsmanager_secret" "credentials" {
  name        = "${var.name}/docdb/notification-service-credentials"
  description = "notification-service's full MONGO_URI-shaped connection string for DocumentDB. Unlike the Postgres services, there's no per-database role split here - this is the only credential this cluster has."

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "credentials" {
  secret_id = aws_secretsmanager_secret.credentials.id
  secret_string = jsonencode({
    # tls=true and the AWS CA bundle requirement are DocumentDB-specific -
    # unlike a bare `mongodb://` URI, connecting to DocumentDB over TLS
    # needs the rds-combined-ca-bundle.pem trust bundle, downloaded and
    # mounted separately (not something Terraform hands you) - notification-
    # service's Mongo client needs that bundle configured, or the
    # connection fails with a TLS trust error, not an auth error.
    mongo_uri = "mongodb://shopstream_admin:${random_password.master.result}@${aws_docdb_cluster.this.endpoint}:27017/shopstream_notifications?tls=true&retryWrites=false"
  })
}
