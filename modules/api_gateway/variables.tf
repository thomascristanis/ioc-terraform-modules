variable "project_name" { type = string }
variable "environment" { type = string }
variable "cognito_issuer" { type = string }
variable "cognito_client_id" { type = string }
variable "alb_listener_arn" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
<<<<<<< fix/apigw-503-private-alb

variable "alb_security_group_id" {
  type        = string
  description = "Security group ID used by API Gateway VPC Link ENIs."
  default     = ""
=======
variable "alb_security_group_id" {
  type        = string
  default     = null
  description = "Security group ID attached to API Gateway VPC link ENIs, expected to allow traffic to the ALB listener."
>>>>>>> master
}

variable "ecs_security_group_id" {
  type        = string
<<<<<<< fix/apigw-503-private-alb
  description = "DEPRECATED: use alb_security_group_id. Kept for backward compatibility."
  default     = ""
=======
  default     = null
  description = "DEPRECATED: use alb_security_group_id."
>>>>>>> master
}
variable "cors_allowed_origins" {
  type        = list(string)
  description = "List of origins allowed for CORS — should be the CloudFront domain in production, localhost in dev"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "enable_waf" {
  description = "Enable a basic AWS WAF web ACL for the API Gateway stage."
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "Maximum number of requests from a single IP in a 5-minute period."
  type        = number
  default     = 2000
}
