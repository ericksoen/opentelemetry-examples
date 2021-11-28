data "aws_vpc" "vpc" {

  dynamic "filter" {
    for_each = var.vpc_filters

    content {
      name   = filter.key
      values = filter.value
    }
  }
}

locals {
  lb_subnet_ids = data.aws_subnet_ids.public.ids
  use_public_service_ips = var.subnet_configuration.prefer_private_ip == false
  service_subnet_ids = var.subnet_configuration.prefer_private_ip ? data.aws_subnet_ids.private[0].ids : data.aws_subnet_ids.public.ids
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.vpc.id

  dynamic "filter" {
    for_each = var.subnet_configuration.public_subnet_filters

    content {
      name   = filter.key
      values = filter.value
    }
  }
}

data "aws_subnet_ids" "private" {
  count = var.subnet_configuration.prefer_private_ip ? 1 : 0

  vpc_id = data.aws_vpc.vpc.id

  dynamic "filter" {
    for_each = var.subnet_configuration.private_subnet_filters

    content {
      name   = filter.key
      values = filter.value
    }
  }
}


data "aws_route53_zone" "zone" {
  name         = "${var.domain}."
  private_zone = false
}