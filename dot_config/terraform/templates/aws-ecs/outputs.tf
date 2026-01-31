# =============================================================================
# Outputs
# Project: {{PROJECT_NAME}}
# =============================================================================

# =============================================================================
# VPC Outputs
# =============================================================================
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

# =============================================================================
# ECS Outputs
# =============================================================================
output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs_cluster.cluster_id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.cluster_name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_cluster.cluster_arn
}

# =============================================================================
# ECS Service Outputs
# =============================================================================
output "service_name" {
  description = "Name of the ECS service"
  value       = module.ecs_service.service_name
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = module.ecs_service.task_definition_arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.ecs_service.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.ecs_service.alb_zone_id
}
