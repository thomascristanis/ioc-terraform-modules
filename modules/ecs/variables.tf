variable "project_name"      { type = string }
variable "environment"       { type = string }
variable "cluster_arn"       { type = string }
variable "cluster_name"      { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "alb_listener_arn"  { type = string }
variable "alb_security_group_id" { type = string }
variable "vpc_id"            { type = string }
variable "container_image"   { type = string }
variable "app_port"          { type = number }
variable "aws_region"        { type = string }

variable "cpu" {
  type    = number
  default = 256
}

variable "memory" {
  type    = number
  default = 512
}

variable "use_spot_only" {
  description = "true = dev (pure SPOT), false = prod (SPOT + on-demand fallback)"
  type        = bool
  default     = false
}

variable "environment_variables" {
  description = "Container environment variables"
  type        = map(string)
  default     = {}
}
