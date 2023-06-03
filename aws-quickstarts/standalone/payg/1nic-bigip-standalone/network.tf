# Create VPC

resource "aws_vpc" "vpc" {
  cidr_block  = var.cidr
  instance_tenancy = "default"

  tags = merge({
    Name = "${var.prefix}-${var.owner}-vpc"
  },
  local.tags)
}

# Create Subnet(s)
resource "aws_subnet" "mgmt" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.subnet_mgmt
  availability_zone = var.az1
  map_public_ip_on_launch = true

  tags = merge({
    Name = "${var.prefix}-${var.owner}-subnet-mgmt"
  },
  local.tags)
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge({
    Name = "${var.prefix}-${var.owner}-igw"
  },
  local.tags)
}

# Create Route Table
resource "aws_route_table" "pub-rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge({
    Name = "${var.prefix}-${var.owner}-public-rt"
  },
  local.tags)
}

# Associate subnet with route table
resource "aws_route_table_association" "mgmt-subnet-to-rt-ass" {
  subnet_id      = aws_subnet.mgmt.id
  route_table_id = aws_route_table.pub-rt.id
}

