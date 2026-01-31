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

variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "{{GCP_REGION}}"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "gke_node_count" {
  description = "Number of nodes per zone in the GKE cluster"
  type        = number
  default     = 1
}

variable "gke_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "gke_disk_size_gb" {
  description = "Disk size for GKE nodes in GB"
  type        = number
  default     = 50
}

variable "gke_min_node_count" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
  default     = 1
}

variable "gke_max_node_count" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 3
}
