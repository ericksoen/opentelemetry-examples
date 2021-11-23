module "nlb" {
  source = "../modules/route53"

  domain    = var.domain
  subdomain = "${var.otlp_subdomain_prefix}.grpc"

  route53_zone_id = data.aws_route53_zone.zone.id

  records = [aws_lb.nlb.dns_name]
}

module "alb" {
  source = "../modules/route53"

  domain    = var.domain
  subdomain = "${var.otlp_subdomain_prefix}"

  route53_zone_id = data.aws_route53_zone.zone.id

  records = [aws_lb.alb.dns_name]
}