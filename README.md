# Overview

This repository intends to provide useful templates and examples of various [OpenTelemetry](https://opentelemetry.io/)  hosting, security implementation patterns within such core AWS services as ECS (Elastic Container Service), EC2 (Elastic Cloud Compute), and Lambda.

The templates and examples provide a snapshot of functionality at a specific moment in time (late August 2021) and are not guaranteed to function in perpetuity.

These templates and examples are _not_ currently intended for production use (please see _Caveats and Assumptions_ later in this document for additional details).

## OpenTelemetry

OpenTelemetry is a vendor-agnostic observability framework for instrumenting, generating, collecting, and exporting telmetry data. The OpenTelemetry Protocol (OTLP) is vendor neutral, which allows you to send telemetry to multiple backends or change backends entirely&mdash;all without rewriting your code.

OpenTelemetry collectors include both **Agents**, a collector instance running with the application or on the same host as a sidecar or daemonset, and a **Gateway**, a standalone service deployed once per data center or region.

The Agent collectors enables applications to offload responsibilities including batching, retry, encryption, and more. This Agent can also enhance telemetry data with metadata such as custom tags or infrastructure information. This Agent pattern frequently simplifies the client implementation of the OpenTelemetry instrumentation. 

The Gateway collectors run as a standalone service and can offer advanced capabilities that include tail-based sampling. A Gateway collector can limit the number of egress points required to send data and consolidate API token management. If a gateway cluster is deployed, it usually receives data from Agents deployed within an environment.

Enterprise vendors who support OpenTelemetry Protocol (OTLP) include AWS, Datadog, Dynatrace, HoneyComb, and New Relic (among others).

Over time, the OpenTelemetry protocol will provide support for telemetry data like _traces_, _metrics_, and _logs_. Currently, only tracing has been released as a generally available, production quality release. Check back on the [OpenTelemetry component status](https://opentelemetry.io/status/) for updates on the development lifecycle for other telemetry data, e.g., metrics and logs.

## Getting Started and Examples

These examples assumes you have at least the following tools/services installed and are somewhat fluent in their use:

1. [Terraform (v1.0.x)](https://www.terraform.io/)
1. [Docker](https://www.docker.com/)
1. [Python (v3.8.x)](https://www.python.org/downloads/)
1. [AWS CLI](https://aws.amazon.com/cli/)

The [examples](./examples/README.md) folder has some code samples to help familiarize yourself with some core OpenTelemetry concepts on your local machine before developing, deploying, and instrumenting more complex applications in AWS.

## OpenTelemetry and Application Architecture

The architecture diagram below shows the hosting pattern for [OpenTelemetry collectors](https://opentelemetry.io/docs/concepts/data-collection/#deployment) and our sample application. 

![Open Telemetry Hosting Architecture](./images/OpenTelemetryArchitecture.png)

This architecture diagram _excludes_ two important details. First, there is a separate cluster that runs an authentication service (available at `auth.domain.com` by default). The OpenTelemetry Agent collector running alongside the `ecs` service includes a bearer token on outgoing requests to the OpenTelemetry Gateway. This latter service authenticates token validate against an authentication service endpoint.

Second, the OpenTelemetry configuration for the Gateway service transmits data to [HoneyComb](https://www.honeycomb.io/blog/all-in-on-opentelemetry/). If you're not interested in transmitting telemetry to HoneyComb, remove these configuration lines. Alternatively, HoneyComb has an accessible and easy to use [free tier](https://www.honeycomb.io/pricing/) that you may want to consider.

## Authentication

This sample hosting implementation provides both secure (via bearer token validation) and insecure gateway endpoints (VPC security only) for OTLP data.

As noted in the **Caveats** section below, the AWS OpenTelemetry distro does not currently support extensions such as `bearertokenauth` and `oidc` so the _secure_ option is not available for AWS services that use their distribution, e.g., the Lambda layer for serverless and the Otel CloudWatch agent for EC2 instances.

|Service|Secure|Insecure|
|-|-|-|
|ECS|Yes|Yes|
|EC2|-|Yes|
|Lambda|-|Yes|

Requests made to the root ECS service will transmit telemetry data via both the _secure_ and _insecure_ endpoints. This means that some trace data will be duplicated in your backend store. Since this is a trial implementation only and not production quality infrastructure, this is an acceptable oddity.

## Deployment

Before you deploy any application infrastructure, you first need to create the images (Gateway, Agent, and Application) and package (Lambda) that the infrastructure depends on. 

Creating the images and packages can be executed in any sequence, but the recommendation is to follow the same order used to deploy the infrastructure:

1. OpenTelemetry Gateway Collector image
1. OpenTelemetry Agent Collector image
1. Build Application
   +  Note: this currently excludes the application build process for the EC2 service endpoint, which is packaged during the infrastructure deployment as S3 objects and then installed as part of application bootstrapping

Once you have created the necessary images and packages, deploy the infrastructure components in the recommend sequence. Please see the [infrastructure README](./infra/README.md) for additional guidance.

### Generating trace data

After packaging and deploying your applications, you can start to generate trace data and visualize it via one or more of the configured backends (Jaeger, HoneyComb, etc.).


To generate trace data, navigate to the demo site landing page (a Terraform output value from the application infrastructure deployment).

![Demo Site Landing Page](./images/demo-site-landing-page.png)

The landing page includes links to make HTTP requests to each of the applications behind our load balancer, `/ecs`, `/ec2`, and `/lambda`, respectively. 

The request flow from the root endpoint is as follows: `/ecs --> /ec2 --> /lambda`. Each of the endpoints can also be invoked independently and calls any downstream endpoints.

The landing page also includes a link to the Jaeger UI. Jaeger is an open source application that provides an ingest endpoint and UI. This allows you to visualize trace data, especially if you elect to disable HoneyComb ingest.

## Assumptions and Caveats

### Assumptions

This application is for demonstration purposes only and not intended as production-quality infrastructure and application code. As a result, some assumptions have been made about your infrastructure and environment.

Please note that your experience deploying this infrastructure may differ if some of these assumptions are not true for your environment.

1. This infrastructure will be deployed into the VPC of single AWS region
1. A single VPC can be identified using one or more of the provided [VPC filter criteria](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpcs.html) 
1. Public and private subnets that belong to the VPC above can be identified using one or more provided [subnet filter criteria](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeSubnets.html)
1. An Elastic Container Repository (ECR) already exists for your images
1. A domain and Route53 hosted zone exist that will serve as the _main_
domain for the subdomains created by this project

### Caveats

The caveats noted below attempt to describe some of the technical issues that limit running this service as a production-quality implementation.

1. Bearer token authentication is unevenly implemented across the three application components (an ECS task, EC2 instance, and Lambda function all&mdash;all running behind a load balancer)
   +  The EC2 instance and Lambda function both use the [AWS OpenTelemetry Distro](https://github.com/aws-observability/aws-otel-collector#aws-otel-collector-built-in-components), which does not currently support the `bearertokenauth` extension
   +  The ECS task definition references the `otel/opentelemetry-collector` base image, which provides wider support for extensions
1. Bearer tokens in this implementation are a static value that are not automatically refreshed and _may_ expire at some point depending on your authentication provider
1. Some secrets such as the HoneyComb write key appear in plain-text in both the AWS SSM Parameter Store and the Terraform state file
1. The Authentication provider, via [Keycloak](https://www.keycloak.org/), uses Spot instances for the ECS tasks as well as local storage
   +  If your Spot Fargate task is terminated, you may need to reconfigure the various clients used in the authentication flow before you can transmit telemetry via the secure OTLP endpoint
1. ECR images are pushed to a single repository and differentiated by the image tag

## Open Issues

1. [Add custom attributes to Lambda via tracer](https://github.com/open-telemetry/opentelemetry-lambda/issues/122)
1. [Add attributes to Lambda span via processor](https://github.com/open-telemetry/opentelemetry-lambda/issues/121)
1. Distributed tracing for the Lambda function, regardless of how it is invoked, incorrectly generates a reference to a non-existent parent span.
   +  This breaks the trace directed acyclic graph (DAG) for every Lambda invocation and generates orphaned spans

## Resources

1. [OpenTelemetry](https://opentelemetry.io/)
1. [AWS Distro for OpenTelemetry](https://aws-otel.github.io/docs/introduction/)
1. [HoneyComb is All-In on OpenTelemetry](https://www.honeycomb.io/blog/all-in-on-opentelemetry/)
1. [AWS Observability Recipes](https://aws-observability.github.io/aws-o11y-recipes/)
