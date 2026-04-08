output "scheduler_role_arn" {
  description = "ARN of the IAM role used by EventBridge Scheduler to update the ECS service."
  value       = aws_iam_role.scheduler.arn
}
