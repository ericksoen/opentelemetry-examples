locals {
  honeycomb_base_count = var.honeycomb_base_config.write_key != "" ? 1 : 0
  honeycomb_base_dataset_name = var.honeycomb_base_config.dataset_name != "" ? var.honeycomb_base_config.dataset_name : "${var.resource_prefix}-base"
}

resource "aws_ssm_parameter" "honeycomb_base_write_key" {
  count = local.honeycomb_base_count
  name  = "/${var.resource_prefix}/honeycomb/base-write-key"
  type  = "String"
  value = var.honeycomb_base_config.write_key
}

resource "aws_ssm_parameter" "honeycomb_refinery_write_key" {
  count = local.honeycomb_refinery_count
  name  = "/${var.resource_prefix}/honeycomb/refinery-write-key"
  type  = "String"
  value = var.honeycomb_refinery_config.write_key
}

# See: https://aws-otel.github.io/docs/setup/ecs/config-through-ssm
# for additional details on how to provide a collector configuration
# via a SSM parameter
resource "aws_ssm_parameter" "gateway_config" {
    name = "/${var.resource_prefix}/gateway-config"
    type = "String"
    value = templatefile("${path.module}/otel-gateway-config.tpl", {
      ENABLE_HONEYCOMB_BASE = local.honeycomb_base_count > 0
      HONEYCOMB_BASE_DATASET = local.honeycomb_base_dataset_name,
      ENABLE_HONEYCOMB_REFINERY = local.honeycomb_refinery_count > 0
      HONEYCOMB_REFINERY_DATASET = local.honeycomb_refinery_dataset_name
      HONEYCOMB_REFINERY_URL = local.honeycomb_base_count > 0 ? module.refinery[0].refinery_url : ""
      EXPORTERS = "[logging, otlp/hc, otlphttp]"
    } )
}
# resource "aws_ssm_parameter" "gateway_config" {
#     name = "/${var.resource_prefix}/gateway-config"
#     type = "String"
#     value = templatefile("${path.module}/otel-gateway-config.tpl", {
#       HONEYCOMB_BASE_DATASET = local.honeycomb_base_dataset_name,
#       HONEYCOMB_REFINERY_DATASET = local.honeycomb_base_dataset_name
#       REFINERY_URL = local.honeycomb_refinery_count > 0 ? module.refinery.refinery_url : ""
#     } )
# }