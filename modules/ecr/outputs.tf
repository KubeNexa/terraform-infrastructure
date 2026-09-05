output "repository_urls" {
  description = "Map of service name -> full ECR repository URL. This is the exact string that replaces the Docker Hub path in every Jenkinsfile's IMAGE_NAME once you migrate off Docker Hub (e.g. output[\"user-service\"] + \":<git-sha>\")."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}

output "repository_arns" {
  value = { for name, repo in aws_ecr_repository.this : name => repo.arn }
}
