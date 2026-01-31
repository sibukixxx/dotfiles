# =============================================================================
# Outputs
# Project: {{PROJECT_NAME}}
# =============================================================================

# VPC Outputs
output "network_name" {
  description = "Name of the VPC network"
  value       = module.vpc.network_name
}

output "network_self_link" {
  description = "Self link of the VPC network"
  value       = module.vpc.network_self_link
}

output "private_subnet_name" {
  description = "Name of the private subnet"
  value       = module.vpc.private_subnet_name
}

# GKE Outputs
output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate of the GKE cluster"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.gcp_region} --project ${var.gcp_project_id}"
}
