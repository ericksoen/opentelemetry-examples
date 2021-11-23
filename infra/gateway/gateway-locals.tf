locals {
  honeycomb_enable_base       = var.honeycomb_base_config.write_key != ""
  honeycomb_base_count        = local.honeycomb_enable_base ? 1 : 0
  honeycomb_base_dataset_name = var.honeycomb_base_config.dataset_name != "" ? var.honeycomb_base_config.dataset_name : "${var.resource_prefix}-base"

}

locals {

  honeycomb_enable_refinery = var.honeycomb_refinery_config.write_key != ""

  honeycomb_refinery_count        = local.honeycomb_enable_refinery ? 1 : 0
  honeycomb_refinery_dataset_name = var.honeycomb_refinery_config.dataset_name != "" ? var.honeycomb_refinery_config.dataset_name : "${var.resource_prefix}-refinery"

  honeycomb_refinery_url = local.honeycomb_enable_refinery ? module.refinery[0].refinery_url : ""
}

# Jaeger extension is currently supported in upstream OpenTelemetry collector image
# but is not available in AWS Distro/OpenTelemetry (ADOT) image.
# See: https://github.com/aws-observability/aws-otel-collector/issues/292
locals {
  jaeger_enable = var.enable_jaeger

}

locals {
  lightstep_enable = var.lightstep_config.access_token != ""

}

locals {
  newrelic_enable = var.newrelic_config.api_key != ""

}
locals {
  # Note: the _WRITE_KEY environment variable names in this file
  # must be identical to the $${_WRITE_KEY} variable names in the
  # gateway-config.tpl file or your exporter will not be able to make
  # authorized requests (assuming it is enabled)
  gateway_remote_environment_variables = [
    {
      "name" : "AOT_CONFIG_CONTENT",
      "valueFrom" : aws_ssm_parameter.gateway_config.arn
    },
    {
      "name" : "HONEYCOMB_BASE_WRITE_KEY",
      "valueFrom" : aws_ssm_parameter.honeycomb_base_write_key.arn
    },
    {
      "name" : "HONEYCOMB_REFINERY_WRITE_KEY",
      "valueFrom" : aws_ssm_parameter.honeycomb_base_write_key.arn
    },
    {
      "name" : "LIGHTSTEP_ACCESS_TOKEN",
      "valueFrom" : aws_ssm_parameter.lightstep_access_token.arn
    },
    {
      "name" : "NEWRELIC_API_KEY",
      "valueFrom" : aws_ssm_parameter.newrelic_api_key.arn
    }
  ]
}