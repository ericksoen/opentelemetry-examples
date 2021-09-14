provider "aws" {

  default_tags {
    tags = var.default_tags
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  region_name = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
}
