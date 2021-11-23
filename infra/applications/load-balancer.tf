resource "aws_lb" "alb" {
  name               = "${var.resource_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnet_ids.public.ids
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = module.app.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = data.template_file.homepage.rendered
      status_code  = "200"
    }
  }

}

data "template_file" "homepage" {
  template = file("${path.module}/homepage.template")

  vars = {
    demo_hostname          = module.app.record_name
    root_service_path      = local.primary_rest_resource
    secondary_service_path = local.secondary_rest_resource
    tertiary_service_path  = local.tertiary_rest_resource
  }
}

resource "aws_lb_listener_rule" "proxy" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = module.proxy.target_group_arn
  }

  condition {
    path_pattern {
      values = ["/proxy"]
    }
  }
}

resource "aws_lb_listener_rule" "ecs" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = module.ecs.target_group_arn
  }

  condition {
    path_pattern {
      values = ["/${local.primary_rest_resource}"]
    }
  }
}

resource "aws_lb_listener_rule" "ec2" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = module.ec2.target_group_arn
  }

  condition {
    path_pattern {
      values = ["/${local.secondary_rest_resource}"]
    }
  }
}

resource "aws_lb_listener_rule" "lambda" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 103

  action {
    type             = "forward"
    target_group_arn = module.lambda.target_group_arn
  }

  condition {
    path_pattern {
      values = ["/${local.tertiary_rest_resource}"]
    }
  }
}