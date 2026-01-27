# =============================================================================
# AWS VPC Module
# Creates VPC with public and private subnets, IGW, and optional NAT Gateway
# =============================================================================

# =============================================================================
# VPC
# =============================================================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# =============================================================================
# Internet Gateway
# =============================================================================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# =============================================================================
# Public Subnets
# =============================================================================
resource "aws_subnet" "public" {
  count = length(var.azs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.subnet_newbits, count.index)
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(var.tags, var.public_subnet_tags, {
    Name = "${var.name_prefix}-public-${count.index + 1}"
    Type = "public"
  })
}

# =============================================================================
# Private Subnets
# =============================================================================
resource "aws_subnet" "private" {
  count = length(var.azs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_newbits, count.index + 10)
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, var.private_subnet_tags, {
    Name = "${var.name_prefix}-private-${count.index + 1}"
    Type = "private"
  })
}

# =============================================================================
# NAT Gateway (Optional)
# =============================================================================
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? var.single_nat_gateway ? 1 : length(var.azs) : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? var.single_nat_gateway ? 1 : length(var.azs) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-${count.index + 1}"
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

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

resource "aws_route_table" "private" {
  count = var.enable_nat_gateway ? var.single_nat_gateway ? 1 : length(var.azs) : 1

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
    }
  }

  tags = merge(var.tags, {
    Name = var.single_nat_gateway ? "${var.name_prefix}-private-rt" : "${var.name_prefix}-private-rt-${count.index + 1}"
  })
}

# =============================================================================
# Route Table Associations
# =============================================================================
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.single_nat_gateway || !var.enable_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
}
