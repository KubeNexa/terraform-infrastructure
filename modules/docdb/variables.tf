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
  type = string
}

variable "instance_class" {
  description = "DocumentDB has no t3.micro-equivalent burstable-free-tier option the way RDS does - db.t3.medium is close to the cheapest instance class DocumentDB supports at all, and it still has an hourly cost with no free tier."
  type        = string
  default     = "db.t3.medium"
}

variable "instance_count" {
  description = "Number of instances in the cluster. 1 = no automatic failover target (single point of failure, cheapest). 2+ = one primary plus replicas DocumentDB can fail over to automatically."
  type        = number
  default     = 1
}

variable "engine_version" {
  type    = string
  default = "5.0.0"
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
