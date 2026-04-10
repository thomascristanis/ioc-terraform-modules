output "table_names" {
  description = "Map of table key to created DynamoDB table name."
  value       = { for key, table in aws_dynamodb_table.tables : key => table.name }
}

output "table_arns" {
  description = "Map of table key to created DynamoDB table ARN."
  value       = { for key, table in aws_dynamodb_table.tables : key => table.arn }
}

# Backward-compatible outputs used by current app infra roots.
output "users_table_name" {
  description = "Name of the users table."
  value       = try(aws_dynamodb_table.tables["users"].name, null)
}

output "books_table_name" {
  description = "Name of the books table."
  value       = try(aws_dynamodb_table.tables["books"].name, null)
}

output "subscriptions_table_name" {
  description = "Name of the subscriptions table."
  value       = try(aws_dynamodb_table.tables["subscriptions"].name, null)
}

output "spaces_table_name" {
  description = "Name of the spaces table."
  value       = try(aws_dynamodb_table.tables["spaces"].name, null)
}

output "catalog_table_name" {
  description = "Name of the catalog table."
  value       = try(aws_dynamodb_table.tables["catalog"].name, null)
}

output "tracker_table_name" {
  description = "Name of the tracker table."
  value       = try(aws_dynamodb_table.tables["tracker"].name, null)
}

output "library_access_table_name" {
  description = "Name of the library_access table."
  value       = try(aws_dynamodb_table.tables["library_access"].name, null)
}

output "rate_limits_table_name" {
  description = "Name of the rate_limits table."
  value       = try(aws_dynamodb_table.tables["rate_limits"].name, null)
}
