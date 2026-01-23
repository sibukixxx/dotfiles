# TFLint Configuration
# Docs: https://github.com/terraform-linters/tflint

# TFLint configuration file
config {
  # Enable module inspection
  module = true

  # Disable specific rules (uncomment as needed)
  # disabled_by_default = false
}

# AWS Plugin
plugin "aws" {
  enabled = true
  version = "0.31.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# GCP Plugin (uncomment if using GCP)
# plugin "google" {
#   enabled = true
#   version = "0.27.1"
#   source  = "github.com/terraform-linters/tflint-ruleset-google"
# }

# Azure Plugin (uncomment if using Azure)
# plugin "azurerm" {
#   enabled = true
#   version = "0.26.0"
#   source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
# }

# =============================================================================
# Common Rules
# =============================================================================

# Disallow deprecated (0.11-style) interpolation
rule "terraform_deprecated_interpolation" {
  enabled = true
}

# Disallow legacy dot index syntax
rule "terraform_deprecated_index" {
  enabled = true
}

# Disallow duplicate resource/data names
rule "terraform_duplicate_names" {
  enabled = true
}

# Require terraform block
rule "terraform_required_version" {
  enabled = true
}

# Require provider version constraints
rule "terraform_required_providers" {
  enabled = true
}

# Standard module structure
rule "terraform_standard_module_structure" {
  enabled = true
}

# Naming conventions
rule "terraform_naming_convention" {
  enabled = true

  # Use snake_case for all
  variable {
    format = "snake_case"
  }

  resource {
    format = "snake_case"
  }

  data {
    format = "snake_case"
  }

  output {
    format = "snake_case"
  }

  module {
    format = "snake_case"
  }
}

# Disallow unused variables
rule "terraform_unused_declarations" {
  enabled = true
}

# Require type for variables
rule "terraform_typed_variables" {
  enabled = true
}
