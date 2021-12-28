# Overview

The `dotnet-462` example is not included as a service with our other language examples (`dotnet-core`, `python`) for three primary reasons.

First, the referenced base image `mcr.microsoft.com/dotnet/framework/sdk:4.8` is not available for Linux containers (conversely, the Jaeger image used to visualize OTLP data is exclusively available for Linux containers).

Second, the referenced images are quite large to download and extract (more than 14 GB) and _may_ take more than 20 minutes to execute the first time they are referenced.

Finally, the instrumentation pattern for a `dotnet-462` vs. `dotnet-core` application do not substantially differ from one another.

**Note**: this solution can also be built and run without Docker via Visual Studio.

## Getting Started

From the directory root, build your Docker image:

```ps1
docker build . -t otel-dotnet462
```

Run your image, passing in your OpenTelemetry host for ingesting OTLP/HTTP data as an environment variable 
```ps1
docker run `
    -e OpenTelemetryHttpHost=https:// `
    -it --rm `
    --name otlptest `
    -p 8000:80 otel-dotnet462:latest
```

To invoke your application, make an HTTP request to the application endpoint:

```ps1
curl http://localhost:8000/api/values
```