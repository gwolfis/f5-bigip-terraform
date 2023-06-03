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

resource "aws_subnet" "external" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.subnet_external
  availability_zone = var.az1
  map_public_ip_on_launch = true

  tags = merge({
    Name = "${var.prefix}-${var.owner}-subnet-external"
  },
  local.tags)
}

resource "aws_subnet" "internal" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.subnet_internal
  availability_zone = var.az1
  map_public_ip_on_launch = true

  tags = merge({
    Name = "${var.prefix}-${var.owner}-subnet-internal"
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

# Create NAT Gateway
resource "aws_eip" "ngw-eip" {
  vpc = true
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw-eip.id
  subnet_id     = "${aws_subnet.external.id}"

  tags = merge({
    Name = "${var.prefix}-${var.owner}-ngw"
  },
  local.tags)
}

resource "aws_route_table" "priv-rt" {
  vpc_id = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = merge({
    Name = "${var.prefix}-${var.owner}-private-rt"
  },
  local.tags)
}

# Associate subnet with route table
resource "aws_route_table_association" "mgmt-subnet-to-rt-ass" {
  subnet_id      = aws_subnet.mgmt.id
  route_table_id = aws_route_table.pub-rt.id
}

resource "aws_route_table_association" "external-subnet-to-rt-ass" {
  subnet_id      = aws_subnet.external.id
  route_table_id = aws_route_table.pub-rt.id
}

resource "aws_route_table_association" "internal-subnet-to-rt-ass" {
  subnet_id      = aws_subnet.internal.id
  route_table_id = aws_route_table.priv-rt.id
}
