extensions:
  health_check:
  zpages:
    endpoint: 0.0.0.0:55679
receivers:
  otlp:
    protocols:
      grpc:
      http:
exporters:
  # Jaeger extension is currently supported in upstream OpenTelemetry collector image
  # but is not available in AWS Distro/OpenTelemetry (ADOT) image.
  # See: https://github.com/aws-observability/aws-otel-collector/issues/292
  # jaeger:
  #   endpoint: 0.0.0.0:14250
  #   insecure: true
  logging:
    logLevel: debug
  otlp:
    endpoint: "api.honeycomb.io:443"
    headers:
      "x-honeycomb-team": $${HONEYCOMB_WRITE_KEY}
      "x-honeycomb-dataset": ${HONEYCOMB_BASE_DATASET}
  otlphttp:
    endpoint: "${REFINERY_URL}"
    headers:
      'x-honeycomb-team': "$${HONEYCOMB_WRITE_KEY}"
      'x-honeycomb-dataset': "${HONEYCOMB_REFINERY_DATASET}"      
processors:
  attributes/insert:
    actions:
      - key: "lifecycle"
        value: "dev"
        action: upsert
  batch:
service:
  extensions: [health_check, zpages]
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch, attributes/insert]
      exporters: [logging, otlp, otlphttp]