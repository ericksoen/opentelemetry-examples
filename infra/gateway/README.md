# OpenTelemetry Gateway Infrastructure Overview

This infrastructure creates the OpenTelemetry Gateway collector as an ECS task running inside its own cluster.

## Variables

|Name|Default Value|
|-|-|
|resource_prefix|otel-gateway|
|vpc_filters||
|subnet_filters||
|private_subnet_filters||
|image_repository||
|default_tags||
|honeycomb_write_key||
|honeycomb_dataset||

Update `example-variables.tfvars` with the required values (using the `bearer_token_issuer_url` from the previous `auth` service infrastructure deployment).

```bash
pushd infra/gateway
$ terraform apply -var-file="example-variables.tfvars" -var-file="../shared-example-variables.tfvars"

Outputs:

jaeger_hostname = "jaeger.domain.com"
otlp_authorized_hostname = "otlp.domain.com"
otlp_insecure_hostname = "otlp-insecure.domain.com"
```