# Application Infrastructure Overview

This infrastructure creates the client application and configures any co-deployed agent services to transmit data to the OpenTelemetry Gateway collector.

This client application includes a load balancer that distributes traffic to API endpoints hosted by an ECS task, EC2 instance, and Lambda function.  

## Input Variables

|Name|Default Value|
|-|-|
|resource_prefix|otel-app|
|app_subdomain|demo|
|vpc_filters||
|subnet_filter||
|private_subnet_filters||
|image_repository||
|default_tags||
|domain||
|otlp_hostname||
|jaeger_ui_hostname||

## Deployment

Update the [example-variables.tfvars](./example-variables.tfvars) with the required values. Many of the values from previous steps, e.g., as Terraform output values.

```bash
pushd infra/applications
$ terraform apply -var-file="example-variables.tfvars" -var-file="../shared-example-variables.tfvars"

Outputs:

demo_hostname = "demo.domain.com
```