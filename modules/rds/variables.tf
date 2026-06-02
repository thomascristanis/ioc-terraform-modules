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

variable "vpc_id" {
  description = "VPC ID where the database security group is created."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group (at least 2 AZs required)."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect on the PostgreSQL port (e.g. the ECS app security group)."
  type        = list(string)
  default     = []
}

# --- Engine ---

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16.4"
}

variable "port" {
  description = "Port the database listens on."
  type        = number
  default     = 5432
}

variable "database_name" {
  description = "Name of the initial database created on the instance."
  type        = string
  default     = "app"
}

variable "master_username" {
  description = "Master username for the database."
  type        = string
  default     = "postgres"
}

# --- Instance sizing / storage ---

variable "instance_class" {
  description = "DB instance class. Defaults to db.t4g.micro (dev) / db.t4g.small (prd) when unset."
  type        = string
  default     = ""
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper limit in GB for storage autoscaling. Set to 0 to disable autoscaling."
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (gp3, gp2, io1)."
  type        = string
  default     = "gp3"
}

# --- High availability / durability (overrides the dev/prd defaults) ---

variable "multi_az" {
  description = "Whether to deploy a Multi-AZ standby. Null uses the platform default, which is false for every environment (including prd). Set to true to opt in."
  type        = bool
  default     = null
}

variable "deletion_protection" {
  description = "Whether deletion protection is enabled. Null uses the per-environment default (prd = true, dev = false)."
  type        = bool
  default     = null
}

variable "backup_retention_period" {
  description = "Days to retain automated backups. Null uses the per-environment default (prd = 7, dev = 1)."
  type        = number
  default     = null
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot on destroy. Null uses the per-environment default (prd = false, dev = true)."
  type        = bool
  default     = null
}

variable "performance_insights_enabled" {
  description = "Whether to enable Performance Insights."
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Days to retain Performance Insights data (7, or a multiple of 31 up to 731). Only used when performance_insights_enabled is true."
  type        = number
  default     = 7
}

variable "auto_minor_version_upgrade" {
  description = "Whether to automatically apply minor engine version upgrades during the maintenance window."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Whether to apply changes immediately instead of waiting for the maintenance window. Useful for dev; can cause downtime in prd."
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "ARN of a KMS key for storage encryption. Empty uses the AWS-managed aws/rds key."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
