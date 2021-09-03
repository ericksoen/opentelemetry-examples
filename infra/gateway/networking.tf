data "aws_vpc" "vpc" {

  dynamic "filter" {
    for_each = var.vpc_filters

    content {
      name   = filter.key
      values = filter.value
    }
  }
}

data "aws_subnet_ids" "subnets" {
  vpc_id = data.aws_vpc.vpc.id

  dynamic "filter" {
    for_each = var.subnet_filters

    content {
      name   = filter.key
      values = filter.value
    }
  }
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.vpc.id

  dynamic "filter" {
    for_each = var.private_subnet_filters

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