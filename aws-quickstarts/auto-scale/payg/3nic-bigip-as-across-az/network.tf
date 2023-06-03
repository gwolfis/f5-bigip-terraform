# Create VPC
data "aws_availability_zones" "available" {}

resource "aws_vpc" "vpc" {
  cidr_block  = var.cidr

  tags = merge({
    Name = "${var.prefix}-${var.owner}-vpc"
  },
  local.tags)
}

# Create Subnet(s)
resource "aws_subnet" "mgmt" {
  count = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.10.${1+count.index}.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true

  tags = merge({
    Name = "${var.prefix}-${var.owner}-subnet-mgmt${count.index}"
  },
  local.tags)
}

resource "aws_subnet" "external" {
  count = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.10.${11+count.index}.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true

  tags = merge({
    Name = "${var.prefix}-${var.owner}-subnet-external${count.index}"
  },
  local.tags)
}

resource "aws_subnet" "internal" {
  count = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.10.${21+count.index}.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = false

  tags = merge({
    Name = "${var.prefix}-${var.owner}-subnet-internal${count.index}"
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
  subnet_id     = "${element(aws_subnet.external.*.id, 1)}"

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
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = element(aws_subnet.mgmt.*.id, count.index)
  route_table_id = aws_route_table.pub-rt.id
}

resource "aws_route_table_association" "external-subnet-to-rt-ass" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = element(aws_subnet.external.*.id, count.index)
  route_table_id = aws_route_table.pub-rt.id
}

resource "aws_route_table_association" "internal-subnet-to-rt-ass" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = element(aws_subnet.internal.*.id, count.index)
  route_table_id = aws_route_table.priv-rt.id
}