variable "project_name" {
  description = "Project name used as a prefix for all resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the NAT instance and security group are created."
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet where the NAT instance is launched."
  type        = string
}

variable "private_route_table_id" {
  description = "ID of the private route table to update with the NAT instance as the default gateway."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
