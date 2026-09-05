variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "vpc_cidr_block" {
  description = "Only traffic from inside this VPC (the EKS nodes) can reach the instance - it is never publicly accessible."
  type        = string
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage_gb" {
  type    = number
  default = 20
}

variable "engine_version" {
  type    = string
  default = "15"
}

variable "multi_az" {
  description = "Real HA (synchronous standby in a second AZ, automatic failover) roughly doubles the instance cost. Off by default for a portfolio project; this is exactly the kind of switch worth flipping on and pointing to in an interview as \"here's how I'd make this production-grade.\""
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "deletion_protection" {
  description = "Set true before this ever holds real data - false here only so `terraform destroy` can tear down a dev/portfolio environment without an extra manual step."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

# --- Per-service logical databases -----------------------------------------
variable "service_databases" {
  description = "One entry per service that owns a database on this shared instance. Each gets its own database AND its own role, scoped to only its own database - order-service's credentials physically cannot connect to shopstream_users, even though both live on the same instance."
  type        = list(string)
  default     = ["shopstream_users", "shopstream_products", "shopstream_orders", "shopstream_payments"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
