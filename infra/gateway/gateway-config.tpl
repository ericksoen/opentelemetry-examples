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
  logging:
    logLevel: debug
  otlp/hc:
    endpoint: "api.honeycomb.io:443"
    headers:
      "x-honeycomb-team": $${HONEYCOMB_BASE_WRITE_KEY}
      "x-honeycomb-dataset": ${HONEYCOMB_BASE_DATASET}
  otlphttp:
    endpoint: "${HONEYCOMB_REFINERY_URL}"
    headers:
      'x-honeycomb-team': "$${HONEYCOMB_REFINERY_WRITE_KEY}"
      'x-honeycomb-dataset': "${HONEYCOMB_REFINERY_DATASET}"
  otlp/lightstep:
    endpoint: ingest.lightstep.com:443
    headers:
      "lightstep-access-token": $${LIGHTSTEP_ACCESS_TOKEN}      
  otlp/nr:
    endpoint: otlp.nr-data.net:4317
    headers:
      "api-key": $${NEWRELIC_API_KEY}
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
      exporters: [${EXPORTER_KEYS}]