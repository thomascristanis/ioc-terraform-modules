variable "project_name" {
  description = "Project name used as a prefix for all DynamoDB table names."
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

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "tables" {
  description = "Map of DynamoDB tables to create. Table names are generated as <project_name>_<environment>_<key>."
  type = map(object({
    hash_key  = string
    range_key = optional(string)
    attributes = list(object({
      name = string
      type = string
    }))

    billing_mode   = optional(string, "PAY_PER_REQUEST")
    read_capacity  = optional(number)
    write_capacity = optional(number)

    global_secondary_indexes = optional(list(object({
      name               = string
      hash_key           = string
      range_key          = optional(string)
      projection_type    = string
      non_key_attributes = optional(list(string), [])
      read_capacity      = optional(number)
      write_capacity     = optional(number)
    })), [])

    local_secondary_indexes = optional(list(object({
      name               = string
      range_key          = string
      projection_type    = string
      non_key_attributes = optional(list(string), [])
    })), [])

    ttl = optional(object({
      attribute_name = string
      enabled        = optional(bool, true)
    }))

    stream = optional(object({
      enabled   = bool
      view_type = optional(string)
    }))

    table_class                    = optional(string)
    deletion_protection_enabled    = optional(bool)
    point_in_time_recovery_enabled = optional(bool, true)
    server_side_encryption_enabled = optional(bool, true)
    tags                           = optional(map(string), {})
  }))
}
