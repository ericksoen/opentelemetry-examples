module "nlb" {
  source = "../modules/route53"

  domain    = var.domain
  subdomain = "${var.otlp_subdomain_prefix}.grpc"

  route53_zone_id = data.aws_route53_zone.zone.id

  records = [module.nlb_lb.lb_dns_name]
}

module "alb" {
  source = "../modules/route53"

  domain    = var.domain
  subdomain = var.otlp_subdomain_prefix

  route53_zone_id = data.aws_route53_zone.zone.id

  records = [module.alb_lb.lb_dns_name]
}