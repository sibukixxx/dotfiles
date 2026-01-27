# =============================================================================
# AWS IAM Role Module - Variables
# =============================================================================

variable "name" {
  description = "Name of the IAM role"
  type        = string
}

variable "description" {
  description = "Description of the IAM role"
  type        = string
  default     = "Managed by Terraform"
}

variable "path" {
  description = "Path for the IAM role"
  type        = string
  default     = "/"
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds"
  type        = number
  default     = 3600
}

variable "assume_role_policy" {
  description = "Custom assume role policy JSON. If not provided, uses trusted_services."
  type        = string
  default     = null
}

variable "trusted_services" {
  description = "List of AWS services that can assume this role"
  type        = list(string)
  default     = ["ec2.amazonaws.com"]
}

variable "managed_policy_arns" {
  description = "List of managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policy names to policy JSON documents"
  type        = map(string)
  default     = {}
}

variable "permissions_boundary" {
  description = "ARN of the permissions boundary policy"
  type        = string
  default     = null
}

variable "create_instance_profile" {
  description = "Create an instance profile for this role"
  type        = bool
  default     = false
}

variable "instance_profile_name" {
  description = "Name of the instance profile (defaults to role name)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the IAM role"
  type        = map(string)
  default     = {}
}
