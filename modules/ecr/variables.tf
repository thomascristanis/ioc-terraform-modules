variable "project_name" {
  description = "Project name used as a prefix for all resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prd)."
  type        = string
}

variable "image_count_to_keep" {
  description = "Number of most recent images to retain in ECR lifecycle policy."
  type        = number
  default     = 3
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
