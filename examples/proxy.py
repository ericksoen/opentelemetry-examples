from flask import Flask, send_from_directory, request
import requests
import os
import time
import secrets
import json

OTLP_HTTP_TARGET = os.getenv('OTLP_HTTP_TARGET')
DOWNSTREAM_PYTHON_TARGET = os.getenv('DOWNSTREAM_PYTHON_TARGET')
DOWNSTREAM_DOTNET_TARGET = os.getenv('DOWNSTREAM_DOTNET_TARGET')

print(f"The OTLP target = {OTLP_HTTP_TARGET}")

if not OTLP_HTTP_TARGET:
    raise "Did not find OTLP/HTTP target for application telemetry. Shutting down..."

if not DOWNSTREAM_PYTHON_TARGET:
    raise "Did not find service target for Python example. Shutting down..."

if not DOWNSTREAM_DOTNET_TARGET:
    raise "Did not find service target for Python example. Shutting down..."

app = Flask(__name__)


def span_factory(trace_id, span_id, start_time_unix_nano, end_time_unix_nano, status_code, path, http_method, name = "proxy", service_name="proxy-service"):
    body =  {
    "resourceSpans": [
        {
            "resource": {
                "attributes": [
                {
                    "key": "environment",
                    "value": {
                        "stringValue": "localhost"
                    }
                },
                {
                    "key": "service.name",
                    "value": {
                        "stringValue": service_name
                    }
                }
                ]
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
                        "attributes": [
                            {
                                "key": "http.method",
                                "value": {
                                    "stringValue": http_method
                                }
                            },
                            {
                                "key": "http.status_code",
                                "value": {
                                    "intValue": status_code,
                                }
                            },
                            {
                                "key": "http.route",
                                "value": {
                                    "stringValue": path,
                                }
                            },
                            {
                                "key": "name",
                                "value": {
                                    "stringValue": name,
                                }
                            }
                        ],
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

    return json.dumps(body)

@app.route('/')
def home():
    return send_from_directory('', 'home.html')

@app.route("/proxy")
def hello():

    trace_id = secrets.token_hex(16)
    span_id = secrets.token_hex(8)
    print(trace_id)
    start_time = time.time_ns()

    queryStringParams = request.args

    if "target" not in queryStringParams:
        return {"traceId": trace_id, "errorMessage": "Expected: '?target=\{name\} where name is one of [\"dotnet\", \"python\"]'"}, 400

    target = queryStringParams["target"].lower()

    request_url = None
    if target == "dotnet":
        request_url = DOWNSTREAM_DOTNET_TARGET
    elif target == "python":
        request_url = DOWNSTREAM_PYTHON_TARGET

    if not request_url:
        return {"traceId": trace_id, "errorMessage": "Expected: '?target=\{name\} where name is one of [\"dotnet\", \"python\"]'"}, 400

    # Generate a w3c traceparent header and inject into downstream
    # service calls
    headers = {
        "traceparent": f"00-{trace_id}-{span_id}-01",
        "content-type": "application/json",
    }

    resp = requests.get(request_url, headers = headers)
    end_time = time.time_ns()
    otlp_http_body = span_factory(trace_id, span_id, start_time, end_time, resp.status_code, "/sample", "GET")
    trace_resp = requests.post(f"{OTLP_HTTP_TARGET}/v1/traces", data = otlp_http_body, headers = {
    "Content-Type": "application/json"
    })

    # Observe that the error happened but don't interrupt client flow
    # Ideally, this would happen as a background thread so that it didn't
    # impact client latency as well
    if trace_resp.status_code != 200:
        print(f"Expected 200 status code. Received {trace_resp.status_code} with body = {json.dumps(trace_resp.json())}")        

    return {"traceId": trace_id, "downstreamServiceResponse": resp.json()}, 200

if __name__ == "__main__":
    app.run(debug=True, port=5000)