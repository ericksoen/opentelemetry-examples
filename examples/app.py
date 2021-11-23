from flask import Flask
import requests
import os
import random

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
        resource=Resource.create({SERVICE_NAME: "service"})
    )
)

otlp_target = os.getenv('OTLP_TARGET')

print(f"The OTLP target = {otlp_target}")

if not otlp_target:
    raise "Did not find OTLP target for application telemery. Shutting down..."
otlp_exporter = OTLPSpanExporter(endpoint=otlp_target, insecure=True)
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

tracer = trace.get_tracer(__name__)

app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()

   
@app.route("/sample")
def hello():
    
    with tracer.start_as_current_span("example-request") as f:
        context = f.get_span_context()
        sleepDuration = random.randint(400, 900)
        time.sleep(sleepDuration / 1000)
        requests.get("http://www.example.com")
    return {"message": "hello", "traceId": hex(context.trace_id)[2:]}


app.run(debug=True, port=5000)
