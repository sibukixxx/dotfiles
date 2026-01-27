# =============================================================================
# AWS Security Group Module
# Configurable security group with flexible ingress/egress rules
# =============================================================================

resource "aws_security_group" "main" {
  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# Ingress Rules
# =============================================================================
resource "aws_security_group_rule" "ingress" {
  for_each = { for idx, rule in var.ingress_rules : idx => rule }

  type              = "ingress"
  security_group_id = aws_security_group.main.id

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  description = lookup(each.value, "description", null)

  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks         = lookup(each.value, "ipv6_cidr_blocks", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  self                     = lookup(each.value, "self", null)
  prefix_list_ids          = lookup(each.value, "prefix_list_ids", null)
}

# =============================================================================
# Egress Rules
# =============================================================================
resource "aws_security_group_rule" "egress" {
  for_each = { for idx, rule in var.egress_rules : idx => rule }

  type              = "egress"
  security_group_id = aws_security_group.main.id

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  description = lookup(each.value, "description", null)

  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks         = lookup(each.value, "ipv6_cidr_blocks", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  self                     = lookup(each.value, "self", null)
  prefix_list_ids          = lookup(each.value, "prefix_list_ids", null)
}
