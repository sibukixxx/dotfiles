# =============================================================================
# Outputs
# Project: {{PROJECT_NAME}}
# =============================================================================

output "service_name" {
  description = "Name of the Cloud Run service"
  value       = google_cloud_run_v2_service.main.name
}

output "service_url" {
  description = "URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.main.uri
}

output "service_account_email" {
  description = "Email of the Cloud Run service account"
  value       = google_service_account.cloudrun.email
}

output "vpc_connector_name" {
  description = "Name of the VPC Access Connector"
  value       = var.enable_vpc_connector ? google_vpc_access_connector.main[0].name : null
}

output "latest_revision" {
  description = "Latest revision of the Cloud Run service"
  value       = google_cloud_run_v2_service.main.latest_ready_revision
}
