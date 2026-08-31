variable "region" {
  description = "Mention region"
  type = string
  default = "eu-central-1"
}

variable "bucket_name" {
    description = "Terraform state bucket "
    type = string
}

variable "table_name" {
    description = "Terraform lock"
    type = string
}