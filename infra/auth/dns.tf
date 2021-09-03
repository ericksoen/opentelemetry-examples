data "aws_route53_zone" "zone" {
  name         = "${var.domain}."
  private_zone = false
}

module "auth" {
  source = "../modules/route53"

  domain = var.domain
  subdomain = var.auth_subdomain

  route53_zone_id = data.aws_route53_zone.zone.id

  records = [aws_lb.alb.dns_name]
}