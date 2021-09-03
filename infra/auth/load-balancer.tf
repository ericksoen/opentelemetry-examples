resource "aws_lb" "alb" {
  name               = "${var.resource_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.to_lb.id]
  subnets            = data.aws_subnet_ids.subnets.ids
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = module.auth.certificate_arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.auth.arn

  }

  depends_on = [module.auth]
}

resource "aws_lb_target_group" "auth" {
  name        = "${var.resource_prefix}-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id

  health_check {
    healthy_threshold = 10
    unhealthy_threshold = 10

    interval = 60
  }
}

