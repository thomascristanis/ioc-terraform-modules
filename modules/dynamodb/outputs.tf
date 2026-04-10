output "table_names" {
  description = "Map of table key to created DynamoDB table name."
  value       = { for key, table in aws_dynamodb_table.tables : key => table.name }
}

output "table_arns" {
  description = "Map of table key to created DynamoDB table ARN."
  value       = { for key, table in aws_dynamodb_table.tables : key => table.arn }
}
