variable "project_name" {
  type        = string
  description = "Project name used as a prefix for all resource names."
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, prod)."
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
