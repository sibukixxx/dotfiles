# TFLint Configuration for GCP Cloud Run project

config {
  module = true
}

plugin "google" {
  enabled = true
  version = "0.27.1"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}
