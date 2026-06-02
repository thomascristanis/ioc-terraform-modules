output "db_instance_id" {
  description = "ID of the RDS instance."
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "ARN of the RDS instance."
  value       = aws_db_instance.main.arn
}

output "endpoint" {
  description = "Connection endpoint in host:port format."
  value       = aws_db_instance.main.endpoint
}

output "address" {
  description = "Hostname of the RDS instance."
  value       = aws_db_instance.main.address
}

output "port" {
  description = "Port the database listens on."
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "Name of the initial database."
  value       = aws_db_instance.main.db_name
}

output "security_group_id" {
  description = "ID of the RDS security group."
  value       = aws_security_group.db.id
}

output "credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the master credentials (username/password/host/port/dbname). Grant the ECS task role read access to this ARN."
  value       = aws_secretsmanager_secret.db.arn
}
