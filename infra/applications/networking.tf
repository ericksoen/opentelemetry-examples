data "aws_vpc" "vpc" {

  dynamic "filter" {
    for_each = var.vpc_filters

    content {
      name   = filter.key
      values = filter.value
    }
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.vpc.id

  dynamic "filter" {
    for_each = var.subnet_filters

    content {
      name   = filter.key
      values = filter.value
    }
  }
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.vpc.id

  dynamic "filter" {
    for_each = var.private_subnet_filters

    content {
      name   = filter.key
      values = filter.value
    }
  }
}


data "aws_route53_zone" "zone" {
  name         = "${var.domain}."
  private_zone = false
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.resource_prefix}-alb-sg"
  description = "Allow inbound traffic to the load balancer"

  vpc_id = data.aws_vpc.vpc.id
}

resource "aws_security_group_rule" "https" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "alb_egress" {
  type     = "egress"
  protocol = "all"

  from_port = 0
  to_port   = 0

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}