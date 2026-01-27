# =============================================================================
# ECS Service Module - Outputs
# =============================================================================

output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.main.id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.main.name
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.main.arn
}

output "task_execution_role_arn" {
  description = "ARN of the task execution role"
  value       = aws_iam_role.task_execution.arn
}

output "task_role_arn" {
  description = "ARN of the task role"
  value       = aws_iam_role.task.arn
}

output "security_group_id" {
  description = "ID of the task security group"
  value       = aws_security_group.task.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = var.enable_load_balancer ? aws_lb.main[0].arn : null
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = var.enable_load_balancer ? aws_lb.main[0].dns_name : null
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = var.enable_load_balancer ? aws_lb.main[0].zone_id : null
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = var.enable_load_balancer ? aws_lb_target_group.main[0].arn : null
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.main.name
}
