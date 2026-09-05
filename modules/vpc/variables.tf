variable "name" {
  description = "Prefix used on every resource this module creates (e.g. shopstream-dev)"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across. Two is the minimum for anything using multiple AZs (EKS, RDS Multi-AZ) - one AZ has no failure-domain separation at all."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "true: one shared NAT Gateway for all private subnets (cheaper - ~$32/mo instead of ~$32/mo per AZ, but the NAT Gateway itself becomes a single point of failure for outbound internet from private subnets). false: one NAT Gateway per AZ (real production HA, ~2-3x the cost for a 2-3 AZ VPC)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to every resource in this module"
  type        = map(string)
  default     = {}
}
