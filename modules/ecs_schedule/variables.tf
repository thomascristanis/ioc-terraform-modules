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
