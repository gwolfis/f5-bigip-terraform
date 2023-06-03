# 
# Create Management Network Interfaces
#
resource "aws_network_interface" "mgmt" {
  count           = length(data.aws_availability_zones.available.names)
  subnet_id       = aws_subnet.mgmt.*.id[count.index]
  security_groups = [aws_security_group.mgmt_sg.id]

  tags = merge({
    Name = "${var.prefix}-${var.owner}-mgmt-int${count.index}"
  },
  local.tags)
}

resource "aws_network_interface" "external" {
  count                   = length(data.aws_availability_zones.available.names)
  subnet_id               = aws_subnet.external.*.id[count.index]
  security_groups         = [aws_security_group.external_sg.id]

  tags = merge({
    Name = "${var.prefix}-${var.owner}-ext-int${count.index}"
  },
  local.tags)
}

resource "aws_network_interface" "internal" {
  count           = length(data.aws_availability_zones.available.names)
  subnet_id       = aws_subnet.internal.*.id[count.index]
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
  count                     = length(data.aws_availability_zones.available.names)
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
  count                     = length(data.aws_availability_zones.available.names)
  network_interface         = aws_network_interface.external.*.id[count.index]
  vpc                       = true

  tags = merge({
    Name = "${var.prefix}-${var.owner}-ext-eip${count.index}"
  },
  local.tags)
}

data "template_file" "init_file" {
  count = length(data.aws_availability_zones.available.names)
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
# BIG-IP template
#
resource "aws_launch_template" "bigip" {
  count                = length(data.aws_availability_zones.available.names)
  instance_type        = var.ec2_instance_type
  image_id             = var.f5_ami
  key_name             = var.ec2_key_name
  user_data            = base64encode(data.template_file.init_file[count.index].rendered)

  # set the mgmt interface 
  network_interfaces {
    network_interface_id = aws_network_interface.mgmt.*.id[count.index]
    device_index = 0
  }

  # set the external interface
  network_interfaces {
    network_interface_id = aws_network_interface.external.*.id[count.index]
    device_index = 1
  }

  # set the internal interface
  network_interfaces {
    network_interface_id = aws_network_interface.internal.*.id[count.index]
    device_index = 2
  }

  depends_on = [aws_eip.mgmt]

  tags = merge({
    Name = "${var.prefix}-${var.owner}-bigip${count.index}"
  },
  local.tags)
}

resource "aws_autoscaling_group" "bigip-asg" {
  availability_zones = ["${element(data.aws_availability_zones.available.names.*, 0)}"]
  desired_capacity   = 1
  max_size           = 3
  min_size           = 1

  launch_template {
    id      = "${element(aws_launch_template.bigip.*.id, 0)}"
    version = "$Latest"
  }

  tag {
    key   = "Name"
    value = "${var.prefix}-${var.owner}-as-group"
    propagate_at_launch = true
  }
}
