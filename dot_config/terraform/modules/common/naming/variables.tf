# =============================================================================
# Common Naming Module - Variables
# =============================================================================

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, stg, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prod", "test", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, stg, prod, test, sandbox."
  }
}

variable "prefix" {
  description = "Optional prefix for resource names"
  type        = string
  default     = null
}

variable "suffix" {
  description = "Optional suffix for resource names"
  type        = string
  default     = null
}

variable "delimiter" {
  description = "Delimiter for joining name components"
  type        = string
  default     = "-"
}

variable "additional_tags" {
  description = "Additional tags to merge with standard tags"
  type        = map(string)
  default     = {}
}
