# 
# Create Management Network Interfaces
#
resource "aws_network_interface" "mgmt" {
  subnet_id       = aws_subnet.mgmt.id
  security_groups = [aws_security_group.mgmt_sg.id]

  tags = merge({
    Name = "${var.prefix}-${var.owner}-ext-int"
  },
  local.tags)
}

#
# add an elastic IP to the BIG-IP management interface
#
resource "aws_eip" "mgmt" {
  network_interface = aws_network_interface.mgmt.id
  vpc               = true

  tags = merge({
    Name = "${var.prefix}-${var.owner}-mgmt-eip"
  },
  local.tags)
}

locals {
  f5_onboard = templatefile("${path.module}/onboard.tpl", {
    INIT_URL            = var.INIT_URL
    DO_URL              = var.DO_URL
    AS3_URL             = var.AS3_URL
    TS_URL              = var.TS_URL
    DO_VER              = split("/", var.DO_URL)[7]
    AS3_VER             = split("/", var.AS3_URL)[7]
    TS_VER              = split("/", var.TS_URL)[7]
    aws_access_key      = var.aws_access_key
    aws_secret_key      = var.aws_secret_key
    user_name           = var.user_name
    user_password       = var.user_password
    discovery_tag_key   = var.discovery_tag_key
    discovery_tag_value = var.discovery_tag_value
  })
}

#
# Deploy BIG-IP
#
resource "aws_instance" "bigip" {
  instance_type        = var.ec2_instance_type
  ami                  = var.f5_ami
  key_name             = var.ec2_key_name
  user_data            = local.f5_onboard
  
  root_block_device {
    delete_on_termination = true
  }

  # set the mgmt interface 
  network_interface {
    network_interface_id = aws_network_interface.mgmt.id
    device_index = 0
  }

  depends_on = [aws_eip.mgmt]

  tags = merge({
    Name = "${var.prefix}-${var.owner}-bigip"
  },
  local.tags)
}
