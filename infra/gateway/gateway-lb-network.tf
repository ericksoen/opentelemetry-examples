module "nlb_lb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name               = "${var.resource_prefix}-nlb"
  load_balancer_type = "network"
  internal           = true

  vpc_id  = data.aws_vpc.vpc.id
  subnets = data.aws_subnet_ids.lb.ids
  target_groups = [
    {
      name             = "${var.resource_prefix}-tg"
      backend_protocol = "TCP"
      backend_port     = 4317
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
      protocol        = "TLS"
      certificate_arn = module.nlb.certificate_arn
      action_type     = "forward"
    }
  ]
}