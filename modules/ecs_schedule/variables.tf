variable "project_name" {
  description = "Project name used as a prefix for all resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)."
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name."
  type        = string
}

variable "service_name" {
  description = "ECS service name to stop/start on schedule."
  type        = string
}

variable "aws_region" {
  description = "AWS region where the ECS service runs."
  type        = string
}

variable "stop_cron" {
  description = "EventBridge cron expression for stopping the service (UTC). Default: 22:00 UTC (19:00 BRT)."
  type        = string
  default     = "cron(0 22 * * ? *)"
}

variable "start_cron" {
  description = "EventBridge cron expression for starting the service (UTC). Default: 08:00 UTC (05:00 BRT)."
  type        = string
  default     = "cron(0 8 * * ? *)"
}

variable "scale_down_count" {
  description = "Desired task count when stopping the service (typically 0)."
  type        = number
  default     = 0
}

variable "scale_up_count" {
  description = "Desired task count when starting the service."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
