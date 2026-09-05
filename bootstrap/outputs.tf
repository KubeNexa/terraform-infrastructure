output "bucket_name" {
  value = aws_s3_bucket.tf_state.id
}

output "table_name" {
  value = aws_dynamodb_table.tf_lock.name
}
