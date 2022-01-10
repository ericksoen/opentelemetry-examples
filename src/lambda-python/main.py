import time
import json
from opentelemetry import trace
import boto3

client = boto3.client('s3')
tracer = trace.get_tracer(__name__)

def handler(event, context):


    with tracer.start_as_current_span("list-s3-buckets") as f:

        response = client.list_buckets()
        bucket_count = len(response['Buckets'])
        f.set_attribute("s3.bucket_count", bucket_count)
        time.sleep(.35)
        return {
            "statusCode": 200,
            "isBase64Encoded": False,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"s3.bucket_count": bucket_count}),
        }

if __name__ == "__main__":
    handler(None, None)