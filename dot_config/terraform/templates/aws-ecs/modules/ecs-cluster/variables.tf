# =============================================================================
# ECS Cluster Module - Variables
# =============================================================================

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "capacity_providers" {
  description = "List of capacity providers"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy"
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = number
  }))
  default = [
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 1
    }
  ]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
