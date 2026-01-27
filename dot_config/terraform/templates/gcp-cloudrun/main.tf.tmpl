# =============================================================================
# Main Terraform Configuration
# Project: {{PROJECT_NAME}}
# =============================================================================

locals {
  project_name = var.project_name
  environment  = var.environment
  name_prefix  = "${local.project_name}-${local.environment}"

  common_labels = {
    project     = local.project_name
    environment = local.environment
    managed_by  = "terraform"
  }
}

# =============================================================================
# VPC Network (for VPC Connector)
# =============================================================================
resource "google_compute_network" "main" {
  count = var.enable_vpc_connector ? 1 : 0

  name                    = "${local.name_prefix}-vpc"
  auto_create_subnetworks = false
  project                 = var.gcp_project_id
}

resource "google_compute_subnetwork" "connector" {
  count = var.enable_vpc_connector ? 1 : 0

  name          = "${local.name_prefix}-connector"
  ip_cidr_range = cidrsubnet(var.vpc_cidr, 8, 0)
  region        = var.gcp_region
  network       = google_compute_network.main[0].id
  project       = var.gcp_project_id

  private_ip_google_access = true
}

# =============================================================================
# VPC Access Connector
# =============================================================================
resource "google_vpc_access_connector" "main" {
  count = var.enable_vpc_connector ? 1 : 0

  name          = "${local.name_prefix}-connector"
  region        = var.gcp_region
  project       = var.gcp_project_id
  network       = google_compute_network.main[0].name
  ip_cidr_range = cidrsubnet(var.vpc_cidr, 8, 1)

  min_instances = 2
  max_instances = 3
}

# =============================================================================
# Service Account
# =============================================================================
resource "google_service_account" "cloudrun" {
  account_id   = "${local.name_prefix}-run"
  display_name = "Cloud Run Service Account for ${local.name_prefix}"
  project      = var.gcp_project_id
}

# =============================================================================
# Cloud Run Service
# =============================================================================
resource "google_cloud_run_v2_service" "main" {
  name     = "${local.name_prefix}-service"
  location = var.gcp_region
  project  = var.gcp_project_id

  template {
    service_account = google_service_account.cloudrun.email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    dynamic "vpc_access" {
      for_each = var.enable_vpc_connector ? [1] : []
      content {
        connector = google_vpc_access_connector.main[0].id
        egress    = "PRIVATE_RANGES_ONLY"
      }
    }

    containers {
      image = var.container_image

      ports {
        container_port = var.container_port
      }

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      # Environment variables example
      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      env {
        name  = "PROJECT_NAME"
        value = var.project_name
      }
    }
  }

  labels = local.common_labels

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
    ]
  }
}

# =============================================================================
# IAM - Allow Unauthenticated Access (optional)
# =============================================================================
resource "google_cloud_run_v2_service_iam_member" "public" {
  count = var.allow_unauthenticated ? 1 : 0

  project  = var.gcp_project_id
  location = google_cloud_run_v2_service.main.location
  name     = google_cloud_run_v2_service.main.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# =============================================================================
# Cloud Run Domain Mapping (optional - uncomment to use)
# =============================================================================
# resource "google_cloud_run_domain_mapping" "main" {
#   location = var.gcp_region
#   name     = "your-domain.com"
#   project  = var.gcp_project_id
#
#   metadata {
#     namespace = var.gcp_project_id
#   }
#
#   spec {
#     route_name = google_cloud_run_v2_service.main.name
#   }
# }
