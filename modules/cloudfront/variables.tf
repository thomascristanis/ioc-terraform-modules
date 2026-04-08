variable "project_name" { type = string }
variable "environment" { type = string }

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
