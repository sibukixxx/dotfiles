# =============================================================================
# Variables
# Project: {{PROJECT_NAME}}
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "{{PROJECT_NAME}}"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "{{ENVIRONMENT}}"

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stg, prod."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "{{AWS_REGION}}"
}

# =============================================================================
# VPC Variables
# =============================================================================
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["{{AWS_REGION}}a", "{{AWS_REGION}}c"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

# =============================================================================
# EKS Variables
# =============================================================================
variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.29"
}

# =============================================================================
# Node Group Variables
# =============================================================================
variable "node_instance_types" {
  description = "List of EC2 instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}
