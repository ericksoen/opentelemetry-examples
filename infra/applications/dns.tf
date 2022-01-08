module "app" {
  source = "../modules/route53"

  domain    = var.domain
  subdomain = var.app_subdomain

  route53_zone_id = data.aws_route53_zone.zone.id

  records = [module.lb.lb_dns_name]
}