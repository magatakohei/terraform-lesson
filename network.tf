# ------------------------------
# VPC
# ------------------------------
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.project}-${var.environment}-vpc"
    Project = var.project
    Env     = var.environment
  }
}

# ------------------------------
# Subnet
# ------------------------------

# public subnet
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name    = "${var.project}-${var.environment}-public-subnet-1a"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name    = "${var.project}-${var.environment}-igw"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name    = "${var.project}-${var.environment}-public-route-table"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_route" "public-igw" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.example.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

# private subnet
resource "aws_subnet" "private_1a" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.65.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false
  tags = {
    Name    = "${var.project}-${var.environment}-private-subnet-1a"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_eip" "nat_gateway_1a" {
  vpc        = true
  depends_on = [aws_internet_gateway.example]
}

resource "aws_nat_gateway" "nat_gateway_1a" {
  allocation_id = aws_eip.nat_gateway_1a.id
  subnet_id     = aws_subnet.public_1a.id
  depends_on    = [aws_internet_gateway.example]
  tags = {
    Name    = "${var.project}-${var.environment}-nat-1a"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_route_table" "private_1a" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name    = "${var.project}-${var.environment}-private-1a-route-table"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_route" "private_1a" {
  route_table_id         = aws_route_table.private_1a.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1a.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_1a.id
}
