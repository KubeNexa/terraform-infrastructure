output "endpoint" {
  value = aws_db_instance.this.address
}

output "port" {
  value = aws_db_instance.this.port
}

output "master_username" {
  value = aws_db_instance.this.username
}

output "master_password" {
  value     = random_password.master.result
  sensitive = true
}

output "security_group_id" {
  value = aws_security_group.this.id
}

output "master_credentials_secret_arn" {
  value = aws_secretsmanager_secret.master.arn
}
