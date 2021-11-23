# Overview

OpenTelemetry facilitates the collection of telemetry data via an OpenTelemetry Collector. The OpenTelemetry Collector provide a vendor-agnostic implementation on how to receive and export telemetry data to one or more open-source or commercial backends. A collector can optionally define one or more processors that sit between the receiver and exporter.

OpenTelemetry provides the following [definition](https://opentelemetry.io/docs/concepts/data-collection/#components) for these three components:

* `receivers`: how to get data into the collector
* `processors`: what to do with received data (optional)
* `exporters`: where to send the data 

We'll use a locally hosted example application to demonstrates how to receive, process, and export application traces using some of the more common ingest patterns. 

## Example Application

To get started, execute `docker-compose up --build` to bring up the various components of our example.

This example application has three main components:

1. A Jaeger backend (open-source) to store telemetry data
1. Two OpenTelemetry collectors (agent and gateway) that receive, process, and export traces 
1. Two services (proxy and downstream) that are _each_ available to consumers over HTTP

The proxy service also hosts a [page](http://localhost:5001) with useful resource links, e.g., application endpoints, debug tools, etc. that are hosted as part of this application. 

### Backend stores

A [Jaeger UI](http://localhost:16686) allows users to explore and visualize their application traces. This data persists for the lifetime of the container and then is removed.

If you'd like to transmit data to a different backend store than Jaeger (or to multiple backend store), the [AWS Distro for OpenTelemetry](https://aws-otel.github.io/docs/introduction) documentation provides guidance on how to configure some of the more frequently used commercial backends.

## OpenTelemetry Collectors

In this example the OpenTelemetry Agent and Gateway collectors are deployed side-by-side. In a production-quality deployment, the client application and OpenTelemetry agent are deployed side by side and communicate over the local network. The OpenTelemetry Gateway is deployed and scaled separately. **For our initial foray, flattening the various services into a single, local network is an acceptable tradeoff.**

The [OpenTelemetry collector deployment documentation](https://opentelemetry.io/docs/concepts/data-collection/#deployment) provides some additional guidance on the advantages of separating Agent and Gateway collectors (including a limited number of egress points and API token consolidation).

In our example application, the OpenTelemetry Gateway collector defines the _single_ entrypoint for telemetry before exporter to the configured backend stores. 

## Application Service Integration Patterns

The OpenTelemetry specifies gRPC as the primary transport mechanism for telemetry data. The LightStep [reference guide](https://docs.lightstep.com/docs/send-otlp-over-http-to-lightstep#common-use-cases-for-otlphttp) offers the following common use cases for when you might consider OTLP/HTTP instead:

1. Telemetry instrumentation is in `node.js` or the browser, where HTTP has better performance
1. Internal network architecture doesn't support gRPC
1. Relative library size for gRPC vs. HTTP dependencies

Our example application demonsrates both integration patterns:

1. `service` --> `agent collector` --> `gateway collector` (over gRPC)
1. `service` --> `gateway collector` (over HTTP)

Our [proxy application](http://localhost:5001/proxy) sends data directly to the HTTP receiver endpoint for the Gateway collector. This proxy application also injects trace headers when making a request to an internal, downstream service.

The [downstream service](http://localhost:5000/sample) sends data to the agent collector, which then exports over gRPC to the Gateway collector.

Telemetry for both these integration patterns persists (for the lifetime of the containers) in the Jaeger backend store.

## Try it out

You can make most requests via the command line (with a tool like cURL). The requests are also available from the [application home page](http://localhost:5001)

1. Invoke the proxy service: `curl http://localhost:5001/proxy`
1. Invoke the downstream service: `curl http://localhost:5000/sample`
1. Send OTLP/HTTP data to the gateway collector: `curl -i http://localhost:4318/v1/traces -H "Content-Type:application/json" -d @multiple-spans.json`
    +   Note: since this request uses a static data file, you will need to specify a custom data range (November 11, 2021) in Jaeger to view the trace details 

## Debugging

The [application home page](http://localhost:5001) provides some useful tools to help debug your Agent and Gateway collectors.

|Type|Agent Port|Gateway Port|
|-|-|-|
|Collector Health|13133|13134|
|zPages|55679|55680|
|Metrics|8888|8889|

The current configuration exports structured telemetry logs for both the Agent and Gateway collectors. In addition both collectors output debug-level application logs (bootstrap steps, port utilization, etc.).

Modify the appropriate configuration if you find these logs to be too verbose:

_otel-*-config.yaml_
```yaml
exporters:
  logging:
    logLevel: debug
```

_docker-compose.yaml_
```yaml
services
  gateway:
    image: otel/opentelemetry-collector:latest
    command: ["--config=/etc/otel-config.yaml", "--log-level=ERROR"]
```

## Adding instrumentation to your application

If you want to experiment with different instrumentation concept, modify your [application code](./app.py) and bring up the various services again.

For example, you might configure your application endpoint to accept a query string parameter and then cache the results locally. Update your instrumentation to capture the query string parameter and whether the value was found in the cache or not. 