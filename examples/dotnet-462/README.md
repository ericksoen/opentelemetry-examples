# Overview

The `dotnet-462` example is not included as a service with our other language examples (`dotnet-core`, `python`) for three primary reasons.

First, the referenced base image `mcr.microsoft.com/dotnet/framework/sdk:4.8` is not available for Linux containers (conversely, the Jaeger image used to visualize OTLP data is exclusively available for Linux containers).

Second, the referenced images are quite large to download and extract (more than 14 GB) and _may_ take more than 20 minutes to execute the first time they are referenced. As a comparison point, the total size for _all_ the images referenced via `docker-compose.yaml` for the primary example is slightly more than 2.3 GB.

Finally, the instrumentation pattern for `dotnet-core` (included) and `dotnet-462` (not included) applications do not substantially differ from one another.

These constraints do not prevent you from running the `dotnet-462` example as a standalone application via Visual Studio and sending telemetry to the OpenTelemetry Agent Collector (one of the services exposed via `docker-compose.yaml`). Alternatively, you can run the provided Dockerfile as an independent Windows container to send data _directly_ to your OpenTelemetry vendor datastore, e.g., HoneyComb, Lightstep, or New Relic. Examples of both are provided below.

## Running via Visual Studio

1. Open a separate terminal and run `docker-compose up --build` to launch Jaeger and the OpenTelemetry Agent + Gateway Collectors
1. Open the `opentelemetry-api-4-6-2.sln` in Visual Studio and run the application via IIS Express
1. The default behavior uses the `OpenTelemetryTarget` key from `Web.config` to send traces via gRPC to the OpenTelemetry Agent Collector (defaults to `http://localhost:4317`)
1. Invoke `curl http://localhost:59644/api/values` to generate application traffic
1. View telemetry output in your browser via Jaeger (`http://localhost:16686`)

## Running via Docker

**Note**: This option requires the ability to run Docker _Windows_ containers. We've periodically seen issues switching between Linux and Windows containers (see [Troubleshooting](#Troubleshooting)).

1. Select Docker _Windows_ container (if not selected)
1. Build your Docker image from the `dotnet-462` directory root:

    ```ps1
    docker build . -t otel-dotnet462
    ```

1. Identify the trace ingest endpoint and other requirements for the appropriate vendor (see [OTLP Exporters: Partners](https://aws-otel.github.io/docs/components/otlp-exporter))

1. Run your image, passing in environment variables for the OpenTelemetry ingest endpoint and headers 

```ps1
docker run `
    -e OpenTelemetryTarget=https://vendor-ingest-endpoint.com`
    -e OpenTelemetryHeaders="x-header-key-1=header-value-1,x-header-key-2=header-value-2"
    -it --rm `
    --name otlptest `
    -p 8000:80 otel-dotnet462:latest
```

1. Make an HTTP request to the application endpoint:

    ```ps1
    curl http://localhost:8000/api/values
    ```

## Issues and Troubleshooting

### Cannot resolve host name in Docker Desktop Windows

I've periodically observed issues where Docker Windows container cannot resolve external network addresses like `api.nuget.org` during the NuGet restore process (see [#3810 Cannot resolve host name in Docker Desktop Windows](https://github.com/docker/for-win/issues/3810)).

You can validate if this issue impacts you using the below Docker command:

```bash
docker run -it --rm stefanscherer/busybox-windows curl https://mock.codes/200
```

Note: this issue appears to occur most frequently when switching from Linux to Windows containers. Restarting your workstation _may_ also resolve this issue.