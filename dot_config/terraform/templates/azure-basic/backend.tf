# =============================================================================
# Backend Configuration
# Project: {{PROJECT_NAME}}
# =============================================================================

# Uncomment and configure for remote state storage
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-terraform-state"
#     storage_account_name = "stterraformstate"
#     container_name       = "tfstate"
#     key                  = "{{PROJECT_NAME}}/{{ENVIRONMENT}}/terraform.tfstate"
#   }
# }

# Local backend (default)
# State is stored in terraform.tfstate in the current directory
