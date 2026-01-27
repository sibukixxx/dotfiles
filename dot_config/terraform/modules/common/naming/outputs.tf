# =============================================================================
# Common Naming Module - Outputs
# =============================================================================

output "base_name" {
  description = "Base name without resource type suffix"
  value       = local.base_name
}

output "full_name" {
  description = "Full name including optional suffix"
  value       = local.full_name
}

output "names" {
  description = "Map of generated names for common resource types"
  value       = local.names
}

output "tags" {
  description = "Standard tags to apply to resources"
  value       = local.standard_tags
}

# Individual name outputs for convenience
output "vpc" {
  description = "Name for VPC"
  value       = local.names.vpc
}

output "subnet" {
  description = "Name prefix for subnets"
  value       = local.names.subnet
}

output "security_group" {
  description = "Name for security group"
  value       = local.names.security_group
}

output "ecs_cluster" {
  description = "Name for ECS cluster"
  value       = local.names.ecs_cluster
}

output "eks_cluster" {
  description = "Name for EKS cluster"
  value       = local.names.eks_cluster
}

output "alb" {
  description = "Name for Application Load Balancer"
  value       = local.names.alb
}

output "iam_role" {
  description = "Name for IAM role"
  value       = local.names.iam_role
}

output "cloudwatch_log_group" {
  description = "Name for CloudWatch log group"
  value       = local.names.cloudwatch_log_group
}
