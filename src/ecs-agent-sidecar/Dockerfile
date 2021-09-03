FROM otel/opentelemetry-collector:latest

COPY ./otel-agent-config.yaml /etc/otel/config.yaml

ENTRYPOINT ["/otelcol"]
CMD ["--config", "/etc/otel/config.yaml"]