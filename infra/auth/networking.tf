data "aws_vpc" "vpc" {

  dynamic "filter" {
    for_each = var.vpc_filters

    content {
      name   = filter.key
      values = filter.value
    }
  }
}

data "aws_subnet_ids" "subnets" {
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

resource "aws_security_group" "to_lb" {
  name        = "${var.resource_prefix}-lb-sg"
  description = "Allow traffic to the authorization load balancer"

  vpc_id = data.aws_vpc.vpc.id
}

resource "aws_security_group_rule" "https" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.to_lb.id
}

resource "aws_security_group_rule" "lb_egress" {
  type     = "egress"
  protocol = "all"

  from_port = 0
  to_port   = 0

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.to_lb.id
}

resource "aws_security_group" "service" {
  name        = "${var.resource_prefix}-service-sg"
  description = "Allow traffic from the authorization load balancer to the service"

  vpc_id = data.aws_vpc.vpc.id
}


resource "aws_security_group_rule" "auth_http" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 8080
  to_port   = 8080

  source_security_group_id = aws_security_group.to_lb.id
  security_group_id = aws_security_group.service.id
}

resource "aws_security_group_rule" "service_egress" {
  type     = "egress"
  protocol = "all"

  from_port = 0
  to_port   = 0

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.service.id
}