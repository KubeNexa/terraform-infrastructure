variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "project_name" {
  type    = string
  default = "shopstream"
}

variable "azs" {
  description = "At least 2 required - EKS and Multi-AZ RDS both need spread across failure domains."
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "admin_cidrs" {
  description = "CIDRs allowed to reach the EKS API server's public endpoint. No sane default exists for this one (unlike everything else in this file) - 0.0.0.0/0 would defeat the entire point of having this variable. You must supply your own office/VPN/admin IP ranges in terraform.tfvars before applying."
  type        = list(string)
  # Deliberately no default - see description. `terraform plan` will
  # prompt for this interactively if terraform.tfvars doesn't set it,
  # which is the correct failure mode here (force a decision) rather
  # than silently falling back to something permissive.
}
