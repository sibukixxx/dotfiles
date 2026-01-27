# Terraform Shared Modules Library

Reusable Terraform modules for common infrastructure patterns.

## Directory Structure

```
modules/
├── aws/                    # AWS-specific modules
│   ├── vpc/               # VPC with subnets, IGW, NAT
│   ├── security-group/    # Configurable security groups
│   └── iam-role/          # IAM roles with policies
└── common/                 # Cloud-agnostic modules
    └── naming/            # Consistent resource naming
```

## Usage

Reference modules in your Terraform configuration:

```hcl
module "vpc" {
  source = "~/.config/terraform/modules/aws/vpc"

  name_prefix = "myproject-dev"
  vpc_cidr    = "10.0.0.0/16"
  azs         = ["ap-northeast-1a", "ap-northeast-1c"]

  tags = {
    Project     = "myproject"
    Environment = "dev"
  }
}
```

## Available Modules

### AWS Modules

| Module | Description |
|--------|-------------|
| `aws/vpc` | VPC with public/private subnets, IGW, and optional NAT Gateway |
| `aws/security-group` | Flexible security group with configurable rules |
| `aws/iam-role` | IAM role with assume role policy and managed policies |

### Common Modules

| Module | Description |
|--------|-------------|
| `common/naming` | Generates consistent resource names following conventions |

## Best Practices

1. **Version Pinning**: Use specific module versions in production
2. **Minimal Permissions**: Apply least-privilege principle for IAM
3. **Tagging**: Always pass tags for cost allocation and management
4. **Documentation**: Keep module documentation up to date
