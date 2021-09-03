provider "aws" {

  default_tags {
    tags = var.default_tags
  }
}

data "aws_region" "current" {}

locals {
  region_name = data.aws_region.current.name
}
