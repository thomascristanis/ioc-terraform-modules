variable "project_name" {
  description = "Project name used as a prefix for all resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prd)."
  type        = string
}

variable "aws_region" {
  description = "AWS region used to build service endpoint names."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where endpoints are created."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for interface endpoints."
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "Private route table IDs for gateway endpoints."
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to interface endpoints on TCP/443."
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
