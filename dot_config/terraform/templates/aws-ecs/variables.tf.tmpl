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
# ECS Service Variables
# =============================================================================
variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}

variable "container_image" {
  description = "Docker image for the container"
  type        = string
  default     = "nginx:latest"
}

variable "task_cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for the task in MiB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "enable_load_balancer" {
  description = "Enable Application Load Balancer"
  type        = bool
  default     = true
}
