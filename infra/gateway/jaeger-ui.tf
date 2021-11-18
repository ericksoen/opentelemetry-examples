resource "aws_lb" "jaeger" {
  name               = "${var.resource_prefix}-jaeger-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.jaeger.id]
  subnets            = data.aws_subnet_ids.subnets.ids
}

resource "aws_lb_listener" "jaeger" {
  load_balancer_arn = aws_lb.jaeger.id
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = module.jaeger.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jaeger_ui.arn
  }
}

resource "aws_lb_listener" "telemetry" {
  load_balancer_arn = aws_lb.jaeger.id
  port              = "8443"
  protocol          = "HTTPS"
  certificate_arn   = module.telemetry.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.telemetry.arn
  }
}

resource "aws_lb_target_group" "telemetry" {
  name        = "${var.resource_prefix}-telemetry-tg"
  port        = 55679
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id

  health_check {
    port = 13133
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 10    
  }
}

resource "aws_lb_target_group" "jaeger_ui" {
  name        = "${var.resource_prefix}-jaeger-ui-tg"
  port        = 16686
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id
}

resource "aws_security_group" "jaeger" {
  name        = "${var.resource_prefix}-jaeger-sg"
  description = "Allow inbound traffic to the load balancer"

  vpc_id = data.aws_vpc.vpc.id
}

resource "aws_security_group_rule" "https" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jaeger.id
}

resource "aws_security_group_rule" "https_2" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 8443
  to_port   = 8443

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jaeger.id
}

resource "aws_security_group_rule" "alb_egress" {
  type     = "egress"
  protocol = "all"

  from_port = 0
  to_port   = 0

  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jaeger.id
}