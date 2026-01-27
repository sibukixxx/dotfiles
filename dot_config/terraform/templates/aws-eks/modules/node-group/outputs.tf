# =============================================================================
# EKS Node Group Module - Outputs
# =============================================================================

output "node_group_name" {
  description = "Name of the EKS node group"
  value       = aws_eks_node_group.main.node_group_name
}

output "node_group_id" {
  description = "EKS node group ID"
  value       = aws_eks_node_group.main.id
}

output "node_group_arn" {
  description = "ARN of the EKS node group"
  value       = aws_eks_node_group.main.arn
}

output "node_group_status" {
  description = "Status of the EKS node group"
  value       = aws_eks_node_group.main.status
}

output "node_group_role_arn" {
  description = "IAM role ARN of the EKS node group"
  value       = aws_iam_role.node_group.arn
}

output "node_group_role_name" {
  description = "IAM role name of the EKS node group"
  value       = aws_iam_role.node_group.name
}
