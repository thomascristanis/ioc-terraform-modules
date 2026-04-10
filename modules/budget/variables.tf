variable "project_name" {
  description = "Project name used as a prefix for all resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prd)."
  type        = string
}

variable "daily_limit_usd" {
  description = "Daily cost alert threshold in USD."
  type        = number
}

variable "alert_email" {
  description = "Email address to receive budget alert notifications."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
