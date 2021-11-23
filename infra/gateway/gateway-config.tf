# See: https://aws-otel.github.io/docs/setup/ecs/config-through-ssm
# for additional details on how to provide a collector configuration
# via a SSM parameter
resource "aws_ssm_parameter" "gateway_config" {
  name = "/${var.resource_prefix}/gateway-config"
  type = "String"
  value = templatefile("${path.module}/gateway-config.tpl", {
    HONEYCOMB_BASE_DATASET     = local.honeycomb_base_dataset_name
    HONEYCOMB_REFINERY_DATASET = local.honeycomb_refinery_dataset_name
    HONEYCOMB_REFINERY_URL     = local.honeycomb_refinery_url
    AWS_REGION = data.aws_region.current.name
    EXPORTER_KEYS              = join(", ", [for exporter in local.exporters_map : exporter.key if exporter.enabled])
  })
}

locals {

  # Here we take advantage of the fact that you can define an exporter in your exporters configuration block,
  # but that it remains inactive until it is referenced in _at least_ one service
  # See: https://opentelemetry.io/docs/collector/configuration/#service
  exporters_map = [
    {
      "key" : "logging",
      "enabled" : true,
    },
    {
      "key": "awsxray",
      "enabled": true
    },
    {
      "key" : "otlp/hc",
      "enabled" : local.honeycomb_enable_base
    },
    {
      "key" : "otlphttp",
      "enabled" : local.honeycomb_enable_refinery
    },
    {
      "key" : "otlp/lightstep",
      "enabled" : local.lightstep_enable
    },
    {
      "key" : "otlp/nr",
      "enabled" : local.newrelic_enable
    }
  ]
}