# OpenTelemetry Gateway Infrastructure Overview

This infrastructure creates the OpenTelemetry Gateway collector as an ECS task running inside its own cluster.

## Variables

|Name|Required|
|-|-|
|resource_prefix|No|
|vpc_filters|Yes|
|subnet_configuration|Yes|
|default_tags|Yes|
|honeycomb_base_config|No|
|honeycomb_refinery_config|No|
|lightstep_config|No|
|newrelic_config|No|

```bash
pushd infra/gateway
$ terraform apply -var-file="example-variables.tfvars" -var-file="../shared-example-variables.tfvars"

Outputs:

otlp_grpc_hostname = "otlp.grpc.domain.com"
otlp_https_hostname = "otlp.domain.com"
```