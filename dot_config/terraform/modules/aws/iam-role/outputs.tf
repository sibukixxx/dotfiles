# =============================================================================
# AWS IAM Role Module - Outputs
# =============================================================================

output "arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.main.arn
}

output "id" {
  description = "ID of the IAM role"
  value       = aws_iam_role.main.id
}

output "name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.main.name
}

output "unique_id" {
  description = "Unique ID of the IAM role"
  value       = aws_iam_role.main.unique_id
}

output "instance_profile_arn" {
  description = "ARN of the instance profile"
  value       = var.create_instance_profile ? aws_iam_instance_profile.main[0].arn : null
}

output "instance_profile_name" {
  description = "Name of the instance profile"
  value       = var.create_instance_profile ? aws_iam_instance_profile.main[0].name : null
}
