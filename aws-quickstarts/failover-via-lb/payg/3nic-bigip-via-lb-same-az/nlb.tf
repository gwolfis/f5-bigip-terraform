# Create Target groups
resource "aws_lb_target_group" "tcp80" {
  name        = "${var.prefix}-tcp80-tg"
  target_type = "ip"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_lb_target_group" "tcp443" {
  name        = "${var.prefix}-tcp443-tg"
  target_type = "ip"
  port        = 443
  protocol    = "TCP"
  vpc_id      = aws_vpc.vpc.id
}

# Attach target groups
resource "aws_lb_target_group_attachment" "backend-80" {
  count            = var.default_instance_count
  target_group_arn = aws_lb_target_group.tcp80.arn
  target_id        = "${aws_network_interface.external.*.private_ip[count.index]}"
  port             = 80
}

resource "aws_lb_target_group_attachment" "backend-443" {
  count            = var.default_instance_count
  target_group_arn = aws_lb_target_group.tcp443.arn
  target_id        = "${aws_network_interface.external.*.private_ip[count.index]}"
  port             = 443
}

resource "aws_lb" "nlb" {
    name               = "${var.prefix}-nlb"
    internal           = false
    load_balancer_type = "network"
    subnets            = [aws_subnet.external.id]

    tags = merge({
      name = "${var.prefix}-${var.owner}-nlb"
    },
    local.tags)
}

resource "aws_lb_listener" "front-tcp80" {
    load_balancer_arn = aws_lb.nlb.arn
    port              = 80
    protocol          = "TCP"

    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.tcp80.arn
    }
}

resource "aws_lb_listener" "front-tcp443" {
    load_balancer_arn = aws_lb.nlb.arn
    port              = 443
    protocol          = "TCP"

    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.tcp443.arn
    }
}

