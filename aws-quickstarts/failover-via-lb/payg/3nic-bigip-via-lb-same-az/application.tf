data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "webserver" {
  count = var.server_count

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = var.ec2_key_name
  monitoring             = true
  vpc_security_group_ids = ["${aws_security_group.internal_sg.id}"]
  subnet_id              = aws_subnet.internal.id

  # build user_data file from template
  user_data = <<-EOF
    #! /bin/bash
    sudo apt-get update -y
    sudo apt-get -y install docker.io
    sudo docker run --name f5demo -p 80:80 -p 443:443 -d f5devcentral/f5-demo-app:latest
    EOF

  tags = merge({
    Name = "${var.prefix}-${var.owner}-web-${count.index + 1}"
    "${var.discovery_tag_key}" = "${var.discovery_tag_value}"
  },
  local.tags)
}