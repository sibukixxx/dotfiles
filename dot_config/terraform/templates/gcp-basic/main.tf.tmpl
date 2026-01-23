# =============================================================================
# Main Terraform Configuration
# Project: {{PROJECT_NAME}}
# =============================================================================

locals {
  project_name = var.project_name
  environment  = var.environment

  common_labels = {
    project     = local.project_name
    environment = local.environment
    managed_by  = "terraform"
  }
}

# =============================================================================
# VPC Network
# =============================================================================
resource "google_compute_network" "main" {
  name                    = "${local.project_name}-${local.environment}-vpc"
  auto_create_subnetworks = false
  project                 = var.gcp_project_id
}

# =============================================================================
# Subnets
# =============================================================================
resource "google_compute_subnetwork" "public" {
  name          = "${local.project_name}-${local.environment}-public"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.main.id
  project       = var.gcp_project_id

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "private" {
  name          = "${local.project_name}-${local.environment}-private"
  ip_cidr_range = var.private_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.main.id
  project       = var.gcp_project_id

  private_ip_google_access = true
}

# =============================================================================
# Cloud Router (for NAT)
# =============================================================================
resource "google_compute_router" "main" {
  name    = "${local.project_name}-${local.environment}-router"
  region  = var.gcp_region
  network = google_compute_network.main.id
  project = var.gcp_project_id
}

# =============================================================================
# Cloud NAT
# =============================================================================
resource "google_compute_router_nat" "main" {
  name                               = "${local.project_name}-${local.environment}-nat"
  router                             = google_compute_router.main.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.gcp_project_id

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# =============================================================================
# Firewall Rules
# =============================================================================
resource "google_compute_firewall" "allow_internal" {
  name    = "${local.project_name}-${local.environment}-allow-internal"
  network = google_compute_network.main.name
  project = var.gcp_project_id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [var.public_subnet_cidr, var.private_subnet_cidr]
}

resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "${local.project_name}-${local.environment}-allow-ssh-iap"
  network = google_compute_network.main.name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP's IP range
  source_ranges = ["35.235.240.0/20"]
}
