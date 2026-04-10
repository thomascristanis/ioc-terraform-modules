output "security_group_id" {
  description = "Security group ID attached to interface endpoints."
  value       = aws_security_group.endpoints.id
}

output "ecr_api_endpoint_id" {
  description = "VPC endpoint ID for ECR API."
  value       = aws_vpc_endpoint.ecr_api.id
}

output "ecr_dkr_endpoint_id" {
  description = "VPC endpoint ID for ECR Docker registry."
  value       = aws_vpc_endpoint.ecr_dkr.id
}

output "logs_endpoint_id" {
  description = "VPC endpoint ID for CloudWatch Logs."
  value       = aws_vpc_endpoint.logs.id
}

output "s3_endpoint_id" {
  description = "VPC endpoint ID for S3 gateway endpoint."
  value       = aws_vpc_endpoint.s3.id
}
