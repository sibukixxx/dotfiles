# =============================================================================
# Backend Configuration
# Project: {{PROJECT_NAME}}
# =============================================================================

# Uncomment and configure for remote state storage
# terraform {
#   backend "gcs" {
#     bucket = "{{PROJECT_NAME}}-terraform-state"
#     prefix = "{{ENVIRONMENT}}/cloudrun"
#   }
# }

# Local backend (default)
# State is stored in terraform.tfstate in the current directory
