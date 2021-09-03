FROM otel/opentelemetry-collector:latest
COPY ./otel-gateway-config.yaml /etc/otel/config.yaml
ENTRYPOINT ["/otelcol"]
CMD ["--config", "/etc/otel/config.yaml"]