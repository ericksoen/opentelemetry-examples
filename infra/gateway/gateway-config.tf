resource "aws_ssm_parameter" "honeycomb_write_key" {
  name  = "/${var.resource_prefix}/honeycomb-write-key"
  type  = "String"
  value = var.honeycomb_write_key
}

# See: https://aws-otel.github.io/docs/setup/ecs/config-through-ssm
# for additional details on how to provide a collector configuration
# via a SSM parameter
resource "aws_ssm_parameter" "gateway_config" {
    name = "/${var.resource_prefix}/gateway-config"
    type = "String"
    value = templatefile("${path.module}/otel-gateway-config.tpl", {
      HONEYCOMB_BASE_DATASET = var.honeycomb_dataset,
      HONEYCOMB_REFINERY_DATASET = var.honeycomb_refinery_dataset
      REFINERY_URL = module.refinery.refinery_url,
    } )
}