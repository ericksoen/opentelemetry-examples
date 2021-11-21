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
  %{ if ENABLE_HONEYCOMB_BASE }
  otlp/hc:
    endpoint: "api.honeycomb.io:443"
    headers:
      "x-honeycomb-team": $${HONEYCOMB_BASE_WRITE_KEY}
      "x-honeycomb-dataset": ${HONEYCOMB_BASE_DATASET}
  %{ endif }
  %{ if ENABLE_HONEYCOMB_REFINERY }
  otlphttp:
    endpoint: "${HONEYCOMB_REFINERY_URL}"
    headers:
      'x-honeycomb-team': "$${HONEYCOMB_REFINERY_WRITE_KEY}"
      'x-honeycomb-dataset': "${HONEYCOMB_REFINERY_DATASET}"     
  %{ endif }
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
      exporters: ${EXPORTERS}