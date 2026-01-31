# =============================================================================
# GKE Module - Main
# =============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# =============================================================================
# GKE Cluster
# =============================================================================
resource "google_container_cluster" "this" {
  name     = "${local.name_prefix}-gke"
  location = var.gcp_region
  project  = var.gcp_project_id

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network_name
  subnetwork = var.subnet_name

  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_cidr_name
    services_secondary_range_name = var.services_cidr_name
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Master authorized networks
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All networks"
    }
  }

  # Maintenance policy
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # Logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  resource_labels = var.labels

  # Deletion protection (disable for dev)
  deletion_protection = var.environment == "prod" ? true : false
}

# =============================================================================
# GKE Node Pool
# =============================================================================
resource "google_container_node_pool" "primary" {
  name       = "${local.name_prefix}-primary-pool"
  location   = var.gcp_region
  cluster    = google_container_cluster.this.name
  project    = var.gcp_project_id

  initial_node_count = var.node_count

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = var.environment != "prod"
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-standard"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = var.labels

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}

# =============================================================================
# Service Account for GKE
# =============================================================================
resource "google_service_account" "gke" {
  account_id   = "${local.name_prefix}-gke-sa"
  display_name = "GKE Service Account for ${local.name_prefix}"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "gke_log_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke.email}"
}

resource "google_project_iam_member" "gke_metric_writer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke.email}"
}

resource "google_project_iam_member" "gke_monitoring_viewer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke.email}"
}
