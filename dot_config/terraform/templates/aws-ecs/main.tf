# =============================================================================
# Main Terraform Configuration - ECS
# Project: {{PROJECT_NAME}}
# =============================================================================

locals {
  project_name = var.project_name
  environment  = var.environment
  name_prefix  = "${local.project_name}-${local.environment}"

  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

# =============================================================================
# Data Sources
# =============================================================================
data "aws_availability_zones" "available" {
  state = "available"
}

# =============================================================================
# VPC
# =============================================================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

# =============================================================================
# Subnets
# =============================================================================
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-${count.index + 1}"
    Type = "public"
  })
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-${count.index + 1}"
    Type = "private"
  })
}

# =============================================================================
# Internet Gateway
# =============================================================================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# =============================================================================
# NAT Gateway
# =============================================================================
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-eip"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat"
  })

  depends_on = [aws_internet_gateway.main]
}

# =============================================================================
# Route Tables
# =============================================================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# =============================================================================
# ECS Cluster
# =============================================================================
module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  cluster_name = local.name_prefix
  tags         = local.common_tags
}

# =============================================================================
# ECS Service (Example)
# =============================================================================
module "ecs_service" {
  source = "./modules/ecs-service"

  cluster_id          = module.ecs_cluster.cluster_id
  cluster_name        = module.ecs_cluster.cluster_name
  service_name        = "${local.name_prefix}-app"
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.private[*].id
  public_subnet_ids   = aws_subnet.public[*].id
  container_port      = var.container_port
  container_image     = var.container_image
  cpu                 = var.task_cpu
  memory              = var.task_memory
  desired_count       = var.desired_count
  enable_load_balancer = var.enable_load_balancer

  tags = local.common_tags
}
