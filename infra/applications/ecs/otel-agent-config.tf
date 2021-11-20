resource "aws_ssm_parameter" "agent_config" {
    name = "/${var.resource_prefix}/agent-config"
    type = "String"
    value = templatefile("${path.module}/otel-agent-config.tpl", {
        OTLP_GATEWAY_ENDPOINT = "${var.otlp_hostname}:443"
    } )
}

