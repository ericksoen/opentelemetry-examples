import requests
import json
import os
import secrets
import time

from requests.api import head

TARGET_BASE_URL = os.getenv("TARGET_BASE_URL")
HTTP_TRACE_GATEWAY_URL = os.getenv("HTTP_TRACE_GATEWAY_URL")

BAD_REQUEST_MESSAGE = {
            "statusCode": 400,
            "headers": {
                "content-type": "application/json",
            },
            "body": json.dumps({"message": "bad request"})
        }

def span_factory(trace_id, span_id, start_time_unix_nano, end_time_unix_nano):
    return {
    "resourceSpans": [
        {
            "resource": {
                "attributes": [{
                    "key": "environment",
                    "value": {
                        "stringValue": "localhost"
                    }
                }]
            },
            "instrumentationLibrarySpans": [{
                "spans": [
                    {
                        "traceId": trace_id,
                        "spanId": span_id,
                        "name": "proxy-layer",
                        "kind": 1,
                        "startTimeUnixNano": start_time_unix_nano,
                        "endTimeUnixNano": end_time_unix_nano,
                        "attributes": [{
                            "key": "http.method",
                            "value": {
                                "stringValue": "GET"
                            }
                        }],
                        "droppedAttributesCount": 0,
                        "events": [],
                        "droppedEventsCount": 0,
                        "status": {
                            "code": 1
                        }
                    }
                ],
                "instrumentationLibrary": {
                    "name": "my-own"
                }
            }]
        }
    ]
}
def handler(event, context):

    params = event.get("queryStringParameters")

    if not params:
        print(f"Expected event key \"queryStringParameters\" not set.")
        return BAD_REQUEST_MESSAGE

    target = params.get("target")

    if not target:
        print(f"Expected event key \"queryStringParameters.target\" not set")
        return BAD_REQUEST_MESSAGE

    target = target.lower()
    if target not in ['ecs', 'ec2', 'lambda']:
        print(F"Expected one of [\"ecs\", \"ecs\", \"lambda\"]. Got {target}.")
        return BAD_REQUEST_MESSAGE
    
    trace_id = secrets.token_hex(16)
    span_id = secrets.token_hex(8)

    headers = {
        "traceparent": f"00-{trace_id}-{span_id}-01",
        "content-type": "application/json"
    }

    start_time = time.time_ns()

    resp = requests.get(f"{TARGET_BASE_URL}/{target}", headers = headers)
    end_time = time.time_ns()

    client_body = resp.json()
    client_body["trace_id"] = trace_id
    client_body["span_id"] = span_id

    otlp_http_body = span_factory(trace_id, span_id, start_time, end_time)

    trace_resp = requests.post(f"{HTTP_TRACE_GATEWAY_URL}/v1/traces", data = json.dumps(otlp_http_body), headers = {
    "Content-Type": "application/json"
    })

    if trace_resp.status_code != 200:
        print(f"Expected 200 status code. Received {resp.status_code} with body = {json.dumps(resp.json())}")
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(client_body)
    }