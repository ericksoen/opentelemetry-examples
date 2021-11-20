extensions:
receivers:
  otlp:
    protocols:
      grpc:
      http:
exporters:
  logging:
    loglevel: debug
  otlp:
    endpoint: ${OTLP_GATEWAY_ENDPOINT}
processors:
  attributes/insert:
    actions:
      - key: 'lifecycle'
        value: 'dev'
        action: insert
      - key: 'host-pattern'
        value: 'ecs'
        action: insert
  batch:
service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch, attributes/insert]
      exporters: [logging, otlp]