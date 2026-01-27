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
# VPC Module
# =============================================================================
module "vpc" {
  source = "./modules/vpc"

  project_name   = local.project_name
  environment    = local.environment
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  vpc_cidr       = var.vpc_cidr
  labels         = local.common_labels
}

# =============================================================================
# GKE Module
# =============================================================================
module "gke" {
  source = "./modules/gke"

  project_name      = local.project_name
  environment       = local.environment
  gcp_project_id    = var.gcp_project_id
  gcp_region        = var.gcp_region
  network_name      = module.vpc.network_name
  subnet_name       = module.vpc.private_subnet_name
  pods_cidr_name    = module.vpc.pods_cidr_name
  services_cidr_name = module.vpc.services_cidr_name
  node_count        = var.gke_node_count
  machine_type      = var.gke_machine_type
  disk_size_gb      = var.gke_disk_size_gb
  min_node_count    = var.gke_min_node_count
  max_node_count    = var.gke_max_node_count
  labels            = local.common_labels
}
