# =============================================================================
# VPC Module - Main
# =============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# =============================================================================
# VPC Network
# =============================================================================
resource "google_compute_network" "this" {
  name                    = "${local.name_prefix}-vpc"
  auto_create_subnetworks = false
  project                 = var.gcp_project_id
}

# =============================================================================
# Private Subnet (for GKE nodes)
# =============================================================================
resource "google_compute_subnetwork" "private" {
  name          = "${local.name_prefix}-private"
  ip_cidr_range = cidrsubnet(var.vpc_cidr, 4, 0)
  region        = var.gcp_region
  network       = google_compute_network.this.id
  project       = var.gcp_project_id

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "${local.name_prefix}-pods"
    ip_cidr_range = cidrsubnet(var.vpc_cidr, 4, 1)
  }

  secondary_ip_range {
    range_name    = "${local.name_prefix}-services"
    ip_cidr_range = cidrsubnet(var.vpc_cidr, 8, 32)
  }
}

# =============================================================================
# Cloud Router (for NAT)
# =============================================================================
resource "google_compute_router" "this" {
  name    = "${local.name_prefix}-router"
  region  = var.gcp_region
  network = google_compute_network.this.id
  project = var.gcp_project_id
}

# =============================================================================
# Cloud NAT
# =============================================================================
resource "google_compute_router_nat" "this" {
  name                               = "${local.name_prefix}-nat"
  router                             = google_compute_router.this.name
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
  name    = "${local.name_prefix}-allow-internal"
  network = google_compute_network.this.name
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

  source_ranges = [var.vpc_cidr]
}

resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "${local.name_prefix}-allow-ssh-iap"
  network = google_compute_network.this.name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP's IP range
  source_ranges = ["35.235.240.0/20"]
}
