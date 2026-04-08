output "users_table_name" {
  description = "Name of the DynamoDB table storing user profiles."
  value       = aws_dynamodb_table.users.name
}

output "books_table_name" {
  description = "Name of the DynamoDB table caching book metadata."
  value       = aws_dynamodb_table.books.name
}

output "subscriptions_table_name" {
  description = "Name of the DynamoDB table storing SaaS subscriptions."
  value       = aws_dynamodb_table.subscriptions.name
}

output "spaces_table_name" {
  description = "Name of the DynamoDB table storing library spaces."
  value       = aws_dynamodb_table.spaces.name
}

output "catalog_table_name" {
  description = "Name of the DynamoDB table storing the personal book catalog."
  value       = aws_dynamodb_table.catalog.name
}

output "tracker_table_name" {
  description = "Name of the DynamoDB table storing reading progress."
  value       = aws_dynamodb_table.tracker.name
}

output "library_access_table_name" {
  description = "Name of the DynamoDB table storing library sharing access."
  value       = aws_dynamodb_table.library_access.name
}

output "rate_limits_table_name" {
  description = "Name of the DynamoDB table storing distributed rate-limit counters."
  value       = aws_dynamodb_table.rate_limits.name
}
