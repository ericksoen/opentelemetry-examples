# Overview

These examples are intended to create a local hosting architecture that includes the following components:

1. Client Application
1. OpenTelemetry Agent Collector
1. OpenTelemetry Gateway Collector
1. Jaeger backend and UI to visualize trace data

The flow of telemetry data will be as follows: `client --> agent --> gateway --> Jaeger backend`.

To get started, execute `docker-compose up` to bring up the various services.

In the case of this brief example, the client application, OpenTelemetry Agent and Gateway all sit side by side. In a production-quality implementation, the client application and OpenTelemetry agent are deployed side by side and communicate over the local network while the OpenTelemetry Gateway is deployed and scaled separately. **For our initial foray, flattening the various services into a single, local network is an acceptable tradeoff.**

## Make your first request

To make a request to the client invocation via `curl http://localhost:5000` or your [browser](http://localhost:5000).

## View Telemetry Data

Both the OpenTelemetry collectors configure the `LoggingExporter`. You should immediately see some data output in the console window where the Docker applications are running.

If you navigate to the [Jaeger Client UI](http://localhost:16686) and search for recent telemetry, you should see your most recent request to your client application.

## Adding instrumentation to your application

If you want to experiment with different instrumentation concept, modify your [application code](./app.py) and bring up the various services again.

For example, you might configure your application endpoint to accept a query string parameter and then cache the results locally. Update your instrumentation to capture the query string parameter and whether the value was found in the cache or not. 