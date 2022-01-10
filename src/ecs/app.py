from flask import Flask, request, jsonify
import requests
import random
import os
import time
import boto3

from opentelemetry import trace
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.instrumentation.botocore import BotocoreInstrumentor
from opentelemetry.sdk.extension.aws.resource.ecs import (
    AwsEcsResourceDetector,
)
from opentelemetry.sdk.resources import get_aggregated_resources

trace.set_tracer_provider(
    TracerProvider(
        resource=get_aggregated_resources(
            [
                AwsEcsResourceDetector(),
            ],
            Resource.create({SERVICE_NAME: "ecs-service"})
        )
    )
)

MIN_LATENCY_MS = 500
MAX_LATENCY_MS = 1100
otlp_target = os.getenv('OTLP_TARGET', "http://127.0.0.1:4317")
http_request_target = os.getenv('HTTP_REQUEST_TARGET')
print(f"The OLTP target = {otlp_target}")
otlp_exporter = OTLPSpanExporter(endpoint=otlp_target, insecure=True)
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

tracer = trace.get_tracer(__name__)

client = boto3.client('s3')

app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()
BotocoreInstrumentor().instrument()

@app.route("/status")
def status():
    return {"Success": True}
@app.route("/ecs")
def hello():

    faults = request.headers['x-fault'] if request.headers.get('x-fault') else "00"

    if len(faults):
        print("Invalid fault length. Skipping fault injection")

    is_latency_fault = faults[0] == "1"
    is_server_error_fault = faults[1] == "1"

    latency_ms = random.randint(MIN_LATENCY_MS, MAX_LATENCY_MS) if is_latency_fault else 0

    time.sleep(latency_ms / 1000)

    if is_server_error_fault:
        return jsonify({"message": "internal server error"}), 502

    normal_latency_ms = random.randint(250, 400)

    bucket_count = 0
    with tracer.start_as_current_span('list-s3-buckets-via-ecs') as f:
        
        response = client.list_buckets()

        bucket_count = len(response['Buckets'])

        f.set_attribute('s3.bucket_count', bucket_count)

    with tracer.start_as_current_span("invoke-ec2"):
        time.sleep(normal_latency_ms / 1000)
        resp = requests.get(http_request_target)
    return {"otlp_target": otlp_target, "ec2_response": resp.json()}, resp.status_code