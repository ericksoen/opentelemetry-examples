resource "aws_lb" "nlb" {
  name               = "${var.resource_prefix}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = data.aws_subnet_ids.lb.ids
}

resource "aws_lb_listener" "otlp" {
  load_balancer_arn = aws_lb.nlb.id
  port              = "443"
  protocol          = "TLS"
  certificate_arn   = module.nlb.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.otlp.arn
  }
}

resource "aws_lb_target_group" "otlp" {
  name     = "${var.resource_prefix}-tg"
  port     = 4317
  protocol = "TCP"
  vpc_id   = data.aws_vpc.vpc.id

  target_type = "ip"

  health_check {
    port                = 13133
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
  }
}