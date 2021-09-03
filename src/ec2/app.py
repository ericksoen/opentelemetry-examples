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

import boto3

raw = requests.get('http://169.254.169.254/latest/dynamic/instance-identity/document')

instance_data = raw.json()
client = boto3.client('ssm', region_name=instance_data["region"])

trace.set_tracer_provider(
    TracerProvider(
        resource=Resource.create(
            {
                SERVICE_NAME: "ec2-service",
                "instance.availabilityZone": instance_data["availabilityZone"],
                "instance.architecture": instance_data["architecture"],
                "instance.instanceId": instance_data["instanceId"],
                "instance.imageId": instance_data["imageId"],
                "instance.instanceType": instance_data["instanceType"],
                "instance.region": instance_data["region"],
            }
        )
    )
)

lambda_target_response = client.get_parameter(Name="lambda-target-url")
lambda_target = lambda_target_response['Parameter']['Value']
otlp_target = os.getenv('OTLP_TARGET', "http://127.0.0.1:4317")
print(f"The OLTP target = {otlp_target}")
otlp_exporter = OTLPSpanExporter(endpoint=otlp_target, insecure=True)
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

tracer = trace.get_tracer(__name__)

app = flask.Flask(__name__)
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()

@app.route("/ec2")
def hello():
    tracer = trace.get_tracer(__name__)
    with tracer.start_as_current_span("invoke-lambda") as span:
        requests.get(lambda_target)
    return {"otlp_target": otlp_target}