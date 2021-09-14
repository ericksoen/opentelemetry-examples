resource "aws_lb" "nlb" {
  name               = "${var.resource_prefix}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = data.aws_subnet_ids.subnets.ids
}

resource "aws_lb_listener" "otlp_auth" {
  load_balancer_arn = aws_lb.nlb.id
  port              = "443"
  protocol          = "TLS"
  certificate_arn   = module.otlp.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.otlp_auth.arn
  }
}

resource "aws_lb_target_group" "otlp_auth" {
  name     = "${var.resource_prefix}-auth-tg"
  port     = 4318
  protocol = "TCP"
  vpc_id   = data.aws_vpc.vpc.id

  target_type = "ip"

  health_check {
    port = 13133
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 10    
  }

}

resource "aws_lb_listener" "otlp_insecure" {
  load_balancer_arn = aws_lb.nlb.id
  port              = "8443"
  protocol          = "TLS"
  certificate_arn   = module.otlp_insecure.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.otlp_insecure.arn
  }
}

resource "aws_lb_target_group" "otlp_insecure" {
  name     = "${var.resource_prefix}-insecure-tg"
  port     = 4317
  protocol = "TCP"
  vpc_id   = data.aws_vpc.vpc.id

  target_type = "ip"

  health_check {
    port = 13133
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 10    
  }
}