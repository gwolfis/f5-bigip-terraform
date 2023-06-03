# 
# Create Management Network Interfaces
#
resource "aws_network_interface" "mgmt" {
  subnet_id       = aws_subnet.mgmt.id
  private_ips     = [cidrhost(var.subnet_mgmt, 10)]
  security_groups = [aws_security_group.mgmt_sg.id]

  tags = merge({
    Name = "${var.prefix}-${var.owner}-mgmt-int"
  },
  local.tags)
}

resource "aws_network_interface" "external" {
  subnet_id               = aws_subnet.external.id
  private_ip_list_enabled = true
  private_ip_list         = [cidrhost(var.subnet_external, 10), cidrhost(var.subnet_external, 20)]
  security_groups         = [aws_security_group.external_sg.id]

  tags = merge({
    Name = "${var.prefix}-${var.owner}-ext-int"
  },
  local.tags)
}

resource "aws_network_interface" "internal" {
  subnet_id       = aws_subnet.internal.id
  private_ips     = [cidrhost(var.subnet_internal, 10)]
  security_groups = [aws_security_group.internal_sg.id]

  tags = merge({
    Name = "${var.prefix}-${var.owner}-int-int"
  },
  local.tags)
}

#
# add an EIP to the BIG-IP interfaces
#
resource "aws_eip" "mgmt" {
  network_interface         = aws_network_interface.mgmt.id
  associate_with_private_ip = aws_network_interface.mgmt.private_ip
  vpc                       = true

  depends_on = [
    aws_network_interface.mgmt
  ]

  tags = merge({
    Name = "${var.prefix}-${var.owner}-mgmt-eip"
  },
  local.tags)
}

resource "aws_eip" "external" {
  network_interface         = aws_network_interface.external.id
  associate_with_private_ip = cidrhost(var.subnet_external, 10)
  vpc                       = true
  
  

  tags = merge({
    Name = "${var.prefix}-${var.owner}-ext-eip"
  },
  local.tags)
}

resource "aws_eip" "vip-1" {
  network_interface         = aws_network_interface.external.id
  associate_with_private_ip = cidrhost(var.subnet_external, 20)
  vpc                       = true
  
  depends_on = [
    aws_network_interface.external
  ]

  tags = merge({
    Name = "${var.prefix}-${var.owner}-ext-vip-1"
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
    vip-1               = aws_eip.vip-1.private_ip
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

  # set the external interface
  network_interface {
    network_interface_id = aws_network_interface.external.id
    device_index = 1
  }

  # set the internal interface
  network_interface {
    network_interface_id = aws_network_interface.internal.id
    device_index = 2
  }

  depends_on = [aws_eip.mgmt]

  tags = merge({
    Name = "${var.prefix}-${var.owner}-bigip"
  },
  local.tags)
}

# # Find BIG-IP AMI
# data "aws_ami" "f5_ami" {
#   most_recent = true
#   owners      = ["aws-marketplace"]
#   filter {
#     name   = "name"
#     values = [var.f5_ami_search_name]
#   }
# }

# module "bigip" {
#   source                 = "F5Networks/bigip-module/aws"
#   version                = "1.1.11"
#   prefix                 = var.prefix
#   ec2_key_name           = var.ec2_key_name
#   f5_username            = var.user_name
#   f5_password            = var.user_password
#   f5_ami_search_name     = var.f5_ami_search_name
#   ec2_instance_type      = var.ec2_instance_type
#   mgmt_subnet_ids        = [{ "subnet_id" = aws_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "" }]
#   mgmt_securitygroup_ids = [aws_security_group.mgmt_sg.id]
#   sleep_time             = "30s"
#   custom_user_data       = local.f5_onboard
#   tags                   = local.tags
# }
