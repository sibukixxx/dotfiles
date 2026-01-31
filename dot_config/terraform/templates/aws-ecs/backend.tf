# =============================================================================
# Backend Configuration
# Project: {{PROJECT_NAME}}
# =============================================================================

# Uncomment and configure for remote state storage
# terraform {
#   backend "s3" {
#     bucket         = "{{PROJECT_NAME}}-terraform-state"
#     key            = "ecs/{{ENVIRONMENT}}/terraform.tfstate"
#     region         = "{{AWS_REGION}}"
#     encrypt        = true
#     dynamodb_table = "{{PROJECT_NAME}}-terraform-lock"
#   }
# }
