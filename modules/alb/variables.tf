variable "project_name" {
  description = "Project name used as a prefix for all resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB and security group are created."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ALB (at least 2 AZs required)."
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "DEPRECATED: use subnet_ids."
  type        = list(string)
  default     = []
}

variable "internal" {
  description = "Whether the ALB is internal."
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener. When set, HTTP traffic is redirected to HTTPS."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
