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
  use_public_service_ips = var.subnet_configuration.prefer_private_ip == false
  service_subnet_filters = var.subnet_configuration.prefer_private_ip ? var.subnet_configuration.private_subnet_filters : var.subnet_configuration.public_subnet_filters
}

data "aws_subnet_ids" "lb" {
  vpc_id = data.aws_vpc.vpc.id

  dynamic "filter" {
    for_each = var.subnet_configuration.public_subnet_filters

    content {
      name   = filter.key
      values = filter.value
    }
  }
}

data "aws_subnet_ids" "service" {

  vpc_id = data.aws_vpc.vpc.id

  dynamic "filter" {
    for_each = local.service_subnet_filters

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