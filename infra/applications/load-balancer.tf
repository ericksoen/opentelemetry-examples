data "template_file" "homepage" {
  template = file("${path.module}/homepage.template")

  vars = {
    demo_hostname          = module.app.record_name
    root_service_path      = local.primary_rest_resource
    secondary_service_path = local.secondary_rest_resource
    tertiary_service_path  = local.tertiary_rest_resource
    quatenary_service_path = local.quatenary_rest_resource
  }
}

#tfsec:ignore:aws-elbv2-alb-not-public:exp:2022-01-31 tfsec:ignore:aws-elb-drop-invalid-headers:exp:2022-01-31
module "lb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"  
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnet_ids.lb.ids
  vpc_id = data.aws_vpc.vpc.id
  https_listeners = [
    {
      port              = "443"
      protocol          = "HTTPS"
      ssl_policy        = "ELBSecurityPolicy-2016-08"
      certificate_arn   = module.app.certificate_arn
      action_type = "fixed-response"
      fixed_response = {
        content_type = "text/html"
        message_body = data.template_file.homepage.rendered
        status_code  = "200"

      }
    }
  ]

  https_listener_rules = [
    {
      https_listener_index = 0
      priority = 99
      actions = [{
        type = "forward"
        target_group_index = 0
      }]

      conditions = [{
        path_patterns = ["/proxy"]
      }]
    },
    {
      https_listener_index = 0
      priority = 100
      actions = [{
        type = "forward"
        target_group_index = 1
      }]

      conditions = [{
        path_patterns = ["/${local.primary_rest_resource}"]
      }]
    },
    {
      https_listener_index = 0
      priority = 101
      actions = [{
        type = "forward"
        target_group_index = 2
      }]

      conditions = [{
        path_patterns = ["/${local.secondary_rest_resource}"]
      }]
    },
    {
      https_listener_index = 0
      priority = 103
      actions = [{
        type = "forward"
        target_group_index = 3
      }]

      conditions = [{
        path_patterns = ["/${local.tertiary_rest_resource}"]
      }]
    },
    {
      https_listener_index = 0
      priority = 104
      actions = [{
        type = "forward"
        target_group_index = 4
      }]

      conditions = [{
        path_patterns = ["/${local.quatenary_rest_resource}"]
      }]
    }
  ]
  target_groups = [
    {
      name = "${module.proxy.lambda_function_name}-tg"
      target_type = "lambda"
      targets = {
        proxy = {
          target_id = module.proxy.lambda_alias_arn
        }
      }
    },
    {
      name = "${var.resource_prefix}-ecs-tg"
      backend_protocol = "HTTP"
      backend_port = 5000
      target_type = "ip"
      health_check = {
        enabled = true
        path = "/status"
        interval = 30
      }
    },
    {
      name = "${var.resource_prefix}-lb-ec2-tg"
      backend_protocol = "HTTP"
      backend_port = 5001
      health_check = {
        enabled = true
        path = "/status"
        interval = 30
      }
    },
    {
      name = "${module.lambda.lambda_function_name}-tg"
      target_type = "lambda"
      targets = {
        lambda = {
          target_id = module.lambda.lambda_alias_arn
        }
      }
    },    
    {
      name = "${module.lambda_python.lambda_function_name}-tg"
      target_type = "lambda"
      targets = {
        python_lambda = {
          target_id = module.lambda_python.lambda_alias_arn
        }
      }
    },    
  ]

}