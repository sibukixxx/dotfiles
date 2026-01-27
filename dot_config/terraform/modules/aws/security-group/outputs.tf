# =============================================================================
# AWS Security Group Module - Outputs
# =============================================================================

output "id" {
  description = "ID of the security group"
  value       = aws_security_group.main.id
}

output "arn" {
  description = "ARN of the security group"
  value       = aws_security_group.main.arn
}

output "name" {
  description = "Name of the security group"
  value       = aws_security_group.main.name
}

output "vpc_id" {
  description = "VPC ID of the security group"
  value       = aws_security_group.main.vpc_id
}
