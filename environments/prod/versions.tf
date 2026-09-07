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

  # Same bucket/table as dev (from the one shared bootstrap/), different
  # key - the two environments' state files are separate objects in the
  # same bucket, never overwriting each other. A stricter setup would use
  # an entirely separate bucket (or a separate AWS account) per
  # environment, so a mistake in one environment's IAM permissions can't
  # even theoretically reach the other's state - worth doing before this
  # ever holds a real customer's data, not required to get prod working.
  #   terraform init -backend-config=backend.hcl
  backend "s3" {
    key     = "environments/prod/terraform.tfstate"
    encrypt = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}

# Same operational wrinkle as dev's provider "postgresql" block - see
# that file's comment. Applies here identically: apply needs real
# network access into this VPC, not just AWS credentials.
provider "postgresql" {
  host      = module.rds.endpoint
  port      = module.rds.port
  username  = module.rds.master_username
  password  = module.rds.master_password
  sslmode   = "require"
  superuser = false
}
