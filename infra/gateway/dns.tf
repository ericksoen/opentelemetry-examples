module "otlp" {
  source = "../modules/route53"

  domain = var.domain
  subdomain = "${var.otlp_subdomain}"

  route53_zone_id = data.aws_route53_zone.zone.id

  records = [aws_lb.nlb.dns_name]
}

// This HTTP DNS modules serves a very important (and hopefully
// temporary purpose). We ned to send span details over HTTP
// instead of gRPC from the proxy layer. However, hosting a 
// second listener on the NLB to receive this traffic did
// not work correctly (likely a user error by yours truly).
// Instead, we host a separate DNS and point it to an existing LB
// and then route traffic by path via a listener rule.

// Again, hopefully temporary
module "otlp_http" {
  source = "../modules/route53"

  domain = var.domain
  subdomain = "${var.otlp_subdomain}-http"

  route53_zone_id = data.aws_route53_zone.zone.id

  records = [aws_lb.jaeger.dns_name]
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