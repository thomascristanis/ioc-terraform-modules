output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB (used by API Gateway VPC link integration)."
  value       = aws_lb.main.dns_name
}

output "security_group_id" {
  description = "ID of the ALB security group (passed to ecs module as alb_security_group_id)."
  value       = aws_security_group.alb.id
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener."
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener. Empty string when no certificate is configured."
  value       = local.has_cert ? aws_lb_listener.https[0].arn : ""
}

output "listener_arn" {
  description = "ARN of the active listener to attach ECS target group rules to. HTTPS when certificate is set, HTTP otherwise."
  value       = local.has_cert ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
}
