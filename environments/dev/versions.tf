terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.22"
    }
  }

  # Partial config on purpose - the bucket/table names come from
  # bootstrap/'s own variables (bucket_name, table_name), which are
  # supplied by the person running bootstrap, not fixed here. Run:
  #   terraform init -backend-config=backend.hcl
  # after copying backend.hcl.example -> backend.hcl and filling in the
  # exact bucket/table names bootstrap actually created.
  backend "s3" {
    key     = "environments/dev/terraform.tfstate"
    encrypt = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}

# Configured to reach the RDS instance this same apply creates. This is
# the one real operational wrinkle in this whole setup, worth being
# explicit about rather than hiding: the instance lives in a private
# subnet with publicly_accessible=false (deliberately - see modules/rds),
# so wherever `terraform apply` runs needs actual network access into the
# VPC for this provider to succeed - it is NOT reachable from a laptop or
# a Jenkins agent sitting outside the VPC by default. Two real options,
# neither automated here:
#   1. Run apply from something already inside the VPC (a bastion host,
#      a Cloud9 environment in the VPC, or a Jenkins agent running as an
#      EKS pod once the cluster exists).
#   2. Temporarily set modules/rds's `publicly_accessible` var to true
#      with a security group scoped to your specific IP, apply, then
#      flip it back - workable for a one-time initial setup, not
#      something to leave on.
# This project doesn't include a bastion module - add one if you want
# option 1 automated instead of done by hand.
provider "postgresql" {
  host     = module.rds.endpoint
  port     = module.rds.port
  username = module.rds.master_username
  password = module.rds.master_password
  sslmode  = "require"
  # RDS's master user is NOT a true Postgres superuser (AWS restricts
  # that even for the master account) - telling the provider not to
  # assume superuser avoids it attempting operations RDS will reject.
  superuser = false
}
