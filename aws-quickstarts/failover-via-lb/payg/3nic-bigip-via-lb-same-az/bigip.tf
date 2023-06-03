# 
# Create Management Network Interfaces
#
resource "aws_network_interface" "mgmt" {
  count           = var.default_instance_count
  subnet_id       = aws_subnet.mgmt.id
  security_groups = [aws_security_group.mgmt_sg.id]

  tags = merge({
    Name = "${var.prefix}-${var.owner}-mgmt-int${count.index}"
  },
  local.tags)
}

resource "aws_network_interface" "external" {
  count                   = var.default_instance_count
  subnet_id               = aws_subnet.external.id
  security_groups         = [aws_security_group.external_sg.id]

  tags = merge({
    Name = "${var.prefix}-${var.owner}-ext-int${count.index}"
  },
  local.tags)
}

resource "aws_network_interface" "internal" {
  count           = var.default_instance_count
  subnet_id       = aws_subnet.internal.id
  security_groups = [aws_security_group.internal_sg.id]

  tags = merge({
    Name = "${var.prefix}-${var.owner}-int-int${count.index}"
  },
  local.tags)
}

#
# add an EIP to the BIG-IP interfaces
#
resource "aws_eip" "mgmt" {
  count                     = var.default_instance_count
  network_interface         = aws_network_interface.mgmt.*.id[count.index]
  associate_with_private_ip = aws_network_interface.mgmt.*.private_ip[count.index]
  vpc                       = true

  depends_on = [
    aws_network_interface.mgmt
  ]

  tags = merge({
    Name = "${var.prefix}-${var.owner}-mgmt-eip${count.index}"
  },
  local.tags)
}

resource "aws_eip" "external" {
  count                     = var.default_instance_count
  network_interface         = aws_network_interface.external.*.id[count.index]
  vpc                       = true

  tags = merge({
    Name = "${var.prefix}-${var.owner}-ext-eip${count.index}"
  },
  local.tags)
}

data "template_file" "init_file" {
  count = var.default_instance_count
  template = file("${path.module}/onboard.tpl")
  vars = {
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
    vip-1               = "${aws_network_interface.external.*.private_ip[count.index]}"
  }
}

#
# Deploy BIG-IP
#
resource "aws_instance" "bigip" {
  count                = var.default_instance_count
  instance_type        = var.ec2_instance_type
  ami                  = var.f5_ami
  key_name             = var.ec2_key_name
  user_data            = base64encode(data.template_file.init_file[count.index].rendered)
  
  root_block_device {
    delete_on_termination = true
  }

  # set the mgmt interface 
  network_interface {
    network_interface_id = aws_network_interface.mgmt.*.id[count.index]
    device_index = 0
  }

  # set the external interface
  network_interface {
    network_interface_id = aws_network_interface.external.*.id[count.index]
    device_index = 1
  }

  # set the internal interface
  network_interface {
    network_interface_id = aws_network_interface.internal.*.id[count.index]
    device_index = 2
  }

  depends_on = [aws_eip.mgmt]

  tags = merge({
    Name = "${var.prefix}-${var.owner}-bigip${count.index}"
  },
  local.tags)
}


