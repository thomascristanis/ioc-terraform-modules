variable "project_name" { type = string }
variable "environment" { type = string }
variable "cognito_issuer" { type = string }
variable "cognito_client_id" { type = string }
variable "alb_listener_arn" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "ecs_security_group_id" { type = string }
variable "cors_allowed_origins" {
  type        = list(string)
  description = "List of origins allowed for CORS — should be the CloudFront domain in production, localhost in dev"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
