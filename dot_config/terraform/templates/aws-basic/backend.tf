# =============================================================================
# Backend Configuration
# Project: {{PROJECT_NAME}}
# =============================================================================

# Uncomment and configure for remote state storage
# terraform {
#   backend "s3" {
#     bucket         = "{{PROJECT_NAME}}-terraform-state"
#     key            = "{{ENVIRONMENT}}/terraform.tfstate"
#     region         = "{{AWS_REGION}}"
#     encrypt        = true
#     dynamodb_table = "{{PROJECT_NAME}}-terraform-lock"
#   }
# }

# Local backend (default)
# State is stored in terraform.tfstate in the current directory
