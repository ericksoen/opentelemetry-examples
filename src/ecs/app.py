import flask
import requests
import os

from opentelemetry import trace
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
import time

trace.set_tracer_provider(
    TracerProvider(
        resource=Resource.create({SERVICE_NAME: "ecs-service"})
    )
)

otlp_target = os.getenv('OTLP_TARGET', "http://127.0.0.1:4317")
http_request_target = os.getenv('HTTP_REQUEST_TARGET')
print(f"The OLTP target = {otlp_target}")
otlp_exporter = OTLPSpanExporter(endpoint=otlp_target, insecure=True)
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

tracer = trace.get_tracer(__name__)

app = flask.Flask(__name__)
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()

@app.route("/ecs")
def hello():
    tracer = trace.get_tracer(__name__)
    with tracer.start_as_current_span("invoke-ec2"):
        requests.get(http_request_target)
    return {"otlp_target": otlp_target}