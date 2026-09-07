locals {
  name = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name       = local.name
  cidr_block = var.vpc_cidr_block
  azs        = var.azs
  # false, unlike dev: one NAT Gateway PER AZ, not one shared NAT
  # Gateway for the whole VPC. dev's single_nat_gateway=true default
  # means an AZ outage takes down outbound internet for every private
  # subnet in every AZ simultaneously - exactly the false-sense-of-HA
  # trap flagged when this module was first reviewed. Real cost: this
  # roughly doubles/triples the NAT Gateway line item for a 2-3 AZ VPC.
  single_nat_gateway = false
  tags               = local.common_tags
}

# No module "ecr" here, deliberately - ECR repository names are global
# per AWS account/region, not per-environment. dev's environments/dev/
# main.tf already owns creating "user-service", "order-service", etc.;
# calling this module again here with the same default repository names
# would try to create identically-named repos a second time and fail.
# Both environments share one image registry - images get built once
# and promoted across environments by tag, not rebuilt per environment.
# (A more mature setup would give ECR its own environments/shared/ state
# instead of letting it live inside dev's - not done here, since it's
# organizational cleanup more than a functional gap.)

module "eks" {
  source = "../../modules/eks"

  name               = local.name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  # Both unconfigurable-by-default in dev, both real production
  # requirements: restrict who can even attempt to reach the API server,
  # and keep a real audit trail of what happened at the Kubernetes API
  # level if something goes wrong.
  endpoint_public_access_cidrs = var.admin_cidrs
  enabled_cluster_log_types    = ["api", "audit", "authenticator"]

  tags = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name               = local.name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_cidr_block     = module.vpc.vpc_cidr_block

  # true, unlike dev: a synchronous standby in a second AZ with
  # automatic failover, instead of a single instance with no failover
  # target at all. Roughly doubles this line item's cost.
  multi_az = true

  # Both false in dev specifically so `terraform destroy` tears a
  # practice environment down cleanly. Neither belongs on an environment
  # meant to hold real data - true here means Terraform refuses to
  # destroy this instance without deliberately disabling protection
  # first, and a final snapshot is taken if it ever is destroyed.
  deletion_protection = true
  skip_final_snapshot = false

  tags = local.common_tags
}

module "docdb" {
  source = "../../modules/docdb"

  name               = local.name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_cidr_block     = module.vpc.vpc_cidr_block

  # 2, not dev's default of 1: a second instance DocumentDB can
  # automatically fail over to. This is the single biggest incremental
  # cost change in this whole file - a second db.t3.medium DocumentDB
  # instance roughly doubles DocumentDB's already-significant cost.
  instance_count = 2

  # No deletion_protection here - unlike aws_db_instance (RDS), the
  # aws_docdb_cluster resource has no such argument at all. A final
  # snapshot on destroy is the only safety net DocumentDB offers.
  skip_final_snapshot = false

  tags = local.common_tags
}
