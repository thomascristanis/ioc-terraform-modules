variable "project_name" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_id" { type = string }
variable "private_route_table_id" { type = string }

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
