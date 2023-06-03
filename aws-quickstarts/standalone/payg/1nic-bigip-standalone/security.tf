#
#  AWS Security Groups
#

resource "aws_security_group" "mgmt_sg" {
    name = "allow_specific_ingress_traffic"
    vpc_id = aws_vpc.vpc.id

    ingress {
     from_port = 22
     to_port = 22
     protocol = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
     from_port = 80
     to_port = 80
     protocol = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
     from_port = 443
     to_port = 443
     protocol = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
     from_port = 8443
     to_port = 8443
     protocol = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
     from_port   = 0
     to_port     = 0
     protocol    = "-1"
     cidr_blocks = ["0.0.0.0/0"]
    }

    tags = merge({
      Name = "${var.prefix}-${var.owner}-mgmt-sg"
  },
  local.tags)
}