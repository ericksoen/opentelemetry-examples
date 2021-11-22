# The assumption with vendor keys is that we will store them as SSM
# parameters and then inject them into the container environment at launch
locals {
  default_vendor_key = "EMPTY_STRING"
}
resource "aws_ssm_parameter" "honeycomb_base_write_key" {
  name  = "/${var.resource_prefix}/honeycomb/base-write-key"
  type  = "String"
  value = local.honeycomb_enable_base ? var.honeycomb_base_config.write_key : local.default_vendor_key
}

resource "aws_ssm_parameter" "honeycomb_refinery_write_key" {
  name  = "/${var.resource_prefix}/honeycomb/refinery-write-key"
  type  = "String"
  value = local.honeycomb_enable_refinery ? var.honeycomb_refinery_config.write_key : local.default_vendor_key
}

resource "aws_ssm_parameter" "lightstep_access_token" {
  name  = "/${var.resource_prefix}/lightstep/access-token"
  type  = "String"
  value = local.lightstep_enable ? var.lightstep_config.access_token : local.default_vendor_key
}

resource "aws_ssm_parameter" "newrelic_api_key" {
  name  = "/${var.resource_prefix}/new-relic/api-key"
  type  = "String"
  value = local.newrelic_enable ? var.newrelic_config.api_key : local.default_vendor_key
}