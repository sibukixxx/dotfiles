# =============================================================================
# AWS IAM Role Module
# Creates IAM role with configurable assume role policy and managed policies
# =============================================================================

# =============================================================================
# IAM Role
# =============================================================================
resource "aws_iam_role" "main" {
  name                 = var.name
  description          = var.description
  path                 = var.path
  max_session_duration = var.max_session_duration

  assume_role_policy = var.assume_role_policy != null ? var.assume_role_policy : jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = var.trusted_services
        }
      }
    ]
  })

  permissions_boundary = var.permissions_boundary

  tags = var.tags
}

# =============================================================================
# Managed Policy Attachments
# =============================================================================
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.main.name
  policy_arn = each.value
}

# =============================================================================
# Inline Policies
# =============================================================================
resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.main.id
  policy = each.value
}

# =============================================================================
# Instance Profile (Optional)
# =============================================================================
resource "aws_iam_instance_profile" "main" {
  count = var.create_instance_profile ? 1 : 0

  name = var.instance_profile_name != null ? var.instance_profile_name : var.name
  role = aws_iam_role.main.name
  path = var.path

  tags = var.tags
}
