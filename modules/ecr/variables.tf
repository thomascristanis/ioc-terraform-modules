variable "project_name" { type = string }
variable "environment" { type = string }

variable "image_count_to_keep" {
  description = "Number of most recent images to retain"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
