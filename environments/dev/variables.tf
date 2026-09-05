variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "environment" {
  type    = string
  default = "dev"
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
