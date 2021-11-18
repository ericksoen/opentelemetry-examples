module "otlp" {
  source = "../modules/route53"

  domain = var.domain
  subdomain = "${var.otlp_subdomain}"

  route53_zone_id = data.aws_route53_zone.zone.id

  records = [aws_lb.nlb.dns_name]
}

module "jaeger" {
  source = "../modules/route53"

  domain = var.domain
  subdomain = var.jaeger_subdomain

  route53_zone_id = data.aws_route53_zone.zone.id

  records = [aws_lb.jaeger.dns_name]
}

module "telemetry" {
  source = "../modules/route53"

  domain = var.domain
  subdomain = var.telemetry_subdomain

  route53_zone_id = data.aws_route53_zone.zone.id

  records = [aws_lb.jaeger.dns_name]
}