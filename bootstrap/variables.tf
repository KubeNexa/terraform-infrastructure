variable "region" {
  description = "Mention region"
  type = string
  default = "eu-central-1"
}

variable "bucket_name" {
    description = "Terraform state bucket "
    type = string
}