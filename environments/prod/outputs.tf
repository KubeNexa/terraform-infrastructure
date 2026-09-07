output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  value = module.eks.oidc_provider_url
}

# No ecr_repository_urls output here - this environment has no
# module "ecr" (see main.tf's comment: ECR repos are shared across
# environments, owned by environments/dev/'s state). Run
# `terraform -chdir=../dev output ecr_repository_urls` if you need
# those values while working in this directory.

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "docdb_endpoint" {
  value = module.docdb.endpoint
}

output "service_db_secret_arns" {
  description = "Secrets Manager ARN per service, holding that service's DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD - this is what External Secrets Operator (or an equivalent) reads from to actually create the Kubernetes Secrets every deployment.yaml in the GitOps repo already references but that don't exist yet."
  value       = { for k, v in aws_secretsmanager_secret.service_db : k => v.arn }
}

output "notification_service_mongo_secret_arn" {
  value = module.docdb.credentials_secret_arn
}

output "configure_kubectl" {
  description = "Run this after apply to point kubectl at the new cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
