variable "name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "EKS control plane version"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  description = "Nodes run here - never in a public subnet."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "The control plane's ENIs and any public-facing load balancer live here too - EKS needs both subnet types passed to it."
  type        = list(string)
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT. SPOT is meaningfully cheaper (often 60-70% off) but nodes can be reclaimed by AWS with a 2-minute warning - fine for a portfolio/practice cluster, a real production judgment call for anything with strict availability requirements."
  type        = string
  default     = "ON_DEMAND"
}

variable "tags" {
  type    = map(string)
  default = {}
}
