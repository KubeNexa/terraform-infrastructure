output "endpoint" {
  value = aws_docdb_cluster.this.endpoint
}

output "port" {
  value = aws_docdb_cluster.this.port
}

output "credentials_secret_arn" {
  value = aws_secretsmanager_secret.credentials.arn
}
