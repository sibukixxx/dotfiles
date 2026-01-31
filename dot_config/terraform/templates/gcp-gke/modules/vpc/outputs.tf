# =============================================================================
# VPC Module - Outputs
# =============================================================================

output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.this.name
}

output "network_self_link" {
  description = "Self link of the VPC network"
  value       = google_compute_network.this.self_link
}

output "private_subnet_name" {
  description = "Name of the private subnet"
  value       = google_compute_subnetwork.private.name
}

output "private_subnet_self_link" {
  description = "Self link of the private subnet"
  value       = google_compute_subnetwork.private.self_link
}

output "pods_cidr_name" {
  description = "Name of the secondary range for pods"
  value       = google_compute_subnetwork.private.secondary_ip_range[0].range_name
}

output "services_cidr_name" {
  description = "Name of the secondary range for services"
  value       = google_compute_subnetwork.private.secondary_ip_range[1].range_name
}

output "router_name" {
  description = "Name of the Cloud Router"
  value       = google_compute_router.this.name
}

output "nat_name" {
  description = "Name of the Cloud NAT"
  value       = google_compute_router_nat.this.name
}
