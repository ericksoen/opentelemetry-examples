# Authentication Infrastructure Overview

If you are want to secure OTLP requests from your ECS application service to the OpenTelemetry Gateway collector using the `bearertokenauth` extension (Agent) and `oidc` extension (Gateway), create the authentication infrastructure first.

## Input Variables

|Name|Default Value|
|-|-|
|resource_prefix|opentelemetry-auth|
|auth_subdomain|auth|
|keycloak_user|admin|
|keycloak_password|admin|
|vpc_filters||
|subnet_filters||
|private_subnet_filters||
|default_tags||
|domain||

## Deployment

Use the script below to deploy the authentication service.

```bash
$ pushd infra/auth
$ terraform apply -var-file="example-variables.tfvars" -var-file="../shared-example-variables.tfvars"
...

Outputs:

auth.domain.com
```

## Authentication Configuration

Navigate to the domain name included in the Terraform outputs, login (user name and password defaults to `admin`/`admin`) and follow the instructions from [Securing your OpenTelemetry Collector](https://medium.com/opentelemetry/securing-your-opentelemetry-collector-1a4f9fa5bd6f) to configure your realm and clients.

If you use the recommended naming conventions from the guide above, you should be able to execute the small shell script with minimal modifications.

This script outputs key-value pairs that can be provided as Terraform variables to upcoming infrastructure deployments.

```bash
domain=""
client_secret=""
client_id="agent"
echo "bearer_token_issuer_url=\"https://$domain/auth/realms/opentelemetry\""
curl --silent https://$domain/auth/realms/opentelemetry/protocol/openid-connect/token \
    --data "grant_type=client_credentials&client_id=$client_id&client_secret=$client_secret" \
    | jq -r '"gateway_bearer_token=\"" + (.access_token) + "\""' 
```

For example, the `bearer_token_issuer_url` variable value is provided to the infrastructure deployment for the [OpenTelemetry Gateway collector](../gateway/example-variables.tfvars) to validate bearer tokens for secure traffic. Similarly, the `gateway_bearer_token` is variable value is provided to the [OpenTelemetry Agent collector](../applications/example-variables.tfvars) sidecar that runs along side our application ECS service. This token is used to secure requests by an OpenTelemetry Agent collector to the OpenTelemetry Gateway.
