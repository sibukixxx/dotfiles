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
# EKS Outputs
# =============================================================================
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

# =============================================================================
# Node Group Outputs
# =============================================================================
output "node_group_name" {
  description = "Name of the EKS node group"
  value       = module.node_group.node_group_name
}

output "node_group_status" {
  description = "Status of the EKS node group"
  value       = module.node_group.node_group_status
}

# =============================================================================
# kubectl Configuration
# =============================================================================
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
