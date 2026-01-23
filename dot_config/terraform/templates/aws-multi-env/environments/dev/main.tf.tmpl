# =============================================================================
# Development Environment
# Project: {{PROJECT_NAME}}
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment for remote state
  # backend "s3" {
  #   bucket         = "{{PROJECT_NAME}}-terraform-state"
  #   key            = "dev/terraform.tfstate"
  #   region         = "{{AWS_REGION}}"
  #   encrypt        = true
  #   dynamodb_table = "{{PROJECT_NAME}}-terraform-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-dev"
}

module "vpc" {
  source = "../../modules/vpc"

  name               = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  tags = {
    Project     = var.project_name
    Environment = "dev"
  }
}

# =============================================================================
# Variables
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "{{AWS_REGION}}"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["{{AWS_REGION}}a", "{{AWS_REGION}}c"]
}

# =============================================================================
# Outputs
# =============================================================================

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}
