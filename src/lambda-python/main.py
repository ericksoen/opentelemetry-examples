import time
import json
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

def handler(event, context):

    with tracer.start_as_current_span("example-request") as f:
        message = "hello world"
        f.set_attribute("message", message)
        time.sleep(.35)
        return {
            "statusCode": 200,
            "isBase64Encoded": False,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"message": message}),
        }

if __name__ == "__main__":
    handler(None, None)