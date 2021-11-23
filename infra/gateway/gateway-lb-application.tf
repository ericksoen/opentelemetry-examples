resource "aws_lb" "alb" {
  name               = "${var.resource_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnet_ids.public.ids
}

resource "aws_lb_listener" "default" {
  load_balancer_arn = aws_lb.alb.id
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = module.alb.certificate_arn
  default_action {
    type             = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "{\"message\": \"hello-world\"}"
      status_code = "200"
    }
  }
}

resource "aws_lb_listener_rule" "debug" {
  listener_arn = aws_lb_listener.default.arn
  priority     = 4
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.telemetry.arn
  }

  condition {
    path_pattern {
      values = ["/debug/*"]
    }
  }
}

resource "aws_lb_listener_rule" "metrics" {
  listener_arn = aws_lb_listener.default.arn
  priority     = 5
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.metrics.arn
  }

  condition {
    path_pattern {
      values = ["/metrics"]
    }
  }
}

resource "aws_lb_listener_rule" "otlp_http" {
  listener_arn = aws_lb_listener.default.arn
  priority     = 6

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.otlp_http.arn
  }

  condition {
    path_pattern {
      values = ["/v1/traces"]
    }
  }
}


resource "aws_lb_listener_certificate" "otlp_http" {
  listener_arn    = aws_lb_listener.default.arn
  certificate_arn = module.alb.certificate_arn
}

resource "aws_lb_target_group" "telemetry" {
  name        = "${var.resource_prefix}-telemetry-tg"
  port        = 55679
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id

  health_check {
    enabled             = true
    port                = 13133
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10

  }
}

resource "aws_lb_target_group" "otlp_http" {
  name     = "${var.resource_prefix}-otlp-http-tg"
  port     = 4318
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.vpc.id

  target_type = "ip"

  health_check {
    port                = 13133
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
  }
}

resource "aws_lb_target_group" "metrics" {
  name        = "${var.resource_prefix}-metrics-tg"
  port        = 8888
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id

  health_check {
    enabled             = true
    port                = 13133
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10

  }
}