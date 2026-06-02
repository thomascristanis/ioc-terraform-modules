variable "project_name" {
  description = "Project name used as a prefix for all resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Must be \"dev\" or \"prd\" (production is always \"prd\")."
  type        = string

  validation {
    condition     = contains(["dev", "prd"], var.environment)
    error_message = "environment must be \"dev\" or \"prd\"."
  }
}

variable "price_class" {
  description = "CloudFront price class (PriceClass_100 = US/Canada/Europe, PriceClass_200 adds Asia/ME/Africa, PriceClass_All = global)."
  type        = string
  default     = "PriceClass_100"
}

variable "aliases" {
  description = "Custom domain aliases for the CloudFront distribution. Requires acm_certificate_arn."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for custom domain TLS (must be in us-east-1). Required when aliases is non-empty."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
