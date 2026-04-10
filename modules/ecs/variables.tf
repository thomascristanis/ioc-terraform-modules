variable "project_name" {
  description = "Project name used as a prefix for all resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prd)."
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster to deploy the service into."
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster (used for CloudWatch and IAM scoping)."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the ECS service network configuration."
  type        = list(string)
}

variable "alb_listener_arn" {
  description = "ARN of the ALB HTTPS listener to attach the target group rule to."
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB, used to allow ingress from ALB to the app."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ECS service and security groups are created."
  type        = string
}

variable "container_image" {
  description = "Full container image URI (e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com/app:latest)."
  type        = string
}

variable "app_port" {
  description = "Port the container listens on."
  type        = number
}

variable "aws_region" {
  description = "AWS region for CloudWatch log group and IAM DynamoDB policy."
  type        = string
}

variable "cpu" {
  description = "Fargate task CPU units (256, 512, 1024, 2048, 4096)."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory in MB."
  type        = number
  default     = 512
}

variable "use_spot_only" {
  description = "true = pure FARGATE_SPOT (dev); false = SPOT + on-demand fallback (prd)."
  type        = bool
  default     = false
}

variable "environment_variables" {
  description = "Container environment variables passed as key-value pairs."
  type        = map(string)
  default     = {}
}

variable "health_check_path" {
  description = "ALB health check path for the target group."
  type        = string
  default     = "/health"
}

variable "alb_listener_priority" {
  description = "Priority for the ALB listener rule (1-50000, lower = higher priority)."
  type        = number
  default     = 100
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days."
  type        = number
  default     = 7
}

variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore failing ALB health checks after a new task starts (boot time)."
  type        = number
  default     = 60
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
