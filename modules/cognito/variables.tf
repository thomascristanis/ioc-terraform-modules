variable "project_name" {
  description = "Project name used as a prefix for all resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)."
  type        = string
}

variable "google_client_id" {
  description = "Google OAuth 2.0 client ID for Cognito identity provider."
  type        = string
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google OAuth 2.0 client secret for Cognito identity provider."
  type        = string
  sensitive   = true
}

variable "callback_urls" {
  description = "OAuth callback URLs (frontend URLs)"
  type        = list(string)
}

variable "logout_urls" {
  description = "OAuth logout URLs (frontend URLs)"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
