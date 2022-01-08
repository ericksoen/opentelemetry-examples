
#tfsec:ignore:aws-elbv2-alb-not-public:exp:2022-01-31 tfsec:ignore:aws-elb-drop-invalid-headers:exp:2022-01-31
module "alb_lb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name               = "${var.resource_prefix}-alb"
  load_balancer_type = "application"
  internal           = false

  vpc_id          = data.aws_vpc.vpc.id
  subnets         = data.aws_subnet_ids.lb.ids
  security_groups = [aws_security_group.alb.id]
  target_groups = [
    {
      name             = "${var.resource_prefix}-telemetry-tg"
      backend_protocol = "HTTP"
      backend_port     = 55679
      target_type      = "ip"
      health_check = {
        enabled             = true
        port                = 13133
        healthy_threshold   = 2
        unhealthy_threshold = 2
        interval            = 10
      }
    },
    {
      name             = "${var.resource_prefix}-otlp-http-tg"
      backend_port     = 4318
      backend_protocol = "HTTP"
      target_type      = "ip"
      health_check = {
        port                = 13133
        healthy_threshold   = 2
        unhealthy_threshold = 2
        interval            = 10
      }

    },
    {
      name             = "${var.resource_prefix}-metrics-tg"
      backend_port     = 8888
      backend_protocol = "HTTP"
      target_type      = "ip"
      health_check = {
        enabled             = true
        port                = 13133
        healthy_threshold   = 2
        unhealthy_threshold = 2
        interval            = 10

      }
    }
  ]

  https_listeners = [
    {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.alb.certificate_arn
      action_type     = "fixed-response"
      fixed_response = {
        message_body = "{\"message\": \"hello-world\"}"
        status_code  = "200"
        content_type = "application/json"
      }
    }
  ]

  https_listener_rules = [
    {
      https_listener_index = 0
      priority             = 4
      actions = [
        {
          type               = "forward"
          target_group_index = 0

        }
      ]

      conditions = [{
        path_patterns = ["/debug/*"]
      }]
    },
    {
      https_listener_index = 0
      priority             = 6
      actions = [
        {
          type               = "forward"
          target_group_index = 1
        }
      ]
      conditions = [{
        path_patterns = ["/v1/traces"]
      }]
    },
    {
      https_listener_index = 0
      priority             = 5
      actions = [
        {
          type               = "forward"
          target_group_index = 2
        }
      ]
      conditions = [{
        path_patterns = ["/metrics"]
      }]
    }

  ]

}

resource "aws_lb_listener_certificate" "otlp_http" {
  listener_arn    = module.alb_lb.https_listener_arns[0]
  certificate_arn = module.alb.certificate_arn
}