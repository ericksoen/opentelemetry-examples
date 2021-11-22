import requests
import json
import os
import secrets
import time
import random

TARGET_BASE_URL = os.getenv("TARGET_BASE_URL")
HTTP_TRACE_GATEWAY_URL = os.getenv("HTTP_TRACE_GATEWAY_URL")

AUTH_ERROR_MESSAGE = {"statusCode": 401, "message": "unauthorized"}

BAD_REQUEST_MESSAGE = {"statusCode": 400, "message": "bad request"}

DEFAULT_RESPONSE = {
    "headers": {
        "content-type": "application/json"
    }
}

invocation_count = 0

class AuthorizationError(Exception):
    pass

class BadRequestError(Exception):
    pass

def span_factory(trace_id, span_id, start_time_unix_nano, end_time_unix_nano, status_code, path, http_method, name = "proxy", service_name="proxy-service"):
    body =  {
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
                                    "stringValue": name 
                                }
                            }
                            {
                                "key": "service.name",
                                "value": {
                                    "stringValue": service_name,
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
def handler(event, context):

    # Work around the fact that the handler isn't able
    # to mutate this counter function without declaring
    # it as global
    global invocation_count
    invocation_count +=1 

    message_response = DEFAULT_RESPONSE.copy()
    path = event.get("path")
    method = event.get("httpMethod")
    try:

        trace_id = secrets.token_hex(16)
        span_id = secrets.token_hex(8)

        start_time = time.time_ns()

        is_auth_fault = random.randint(1, 100) > 70

        if (is_auth_fault):
            message_response.update(AUTH_ERROR_MESSAGE)
            raise AuthorizationError("User is not authorized")

        params = event.get("queryStringParameters")

        if not params:
            message_response.update(BAD_REQUEST_MESSAGE)
            raise BadRequestError(f"Expected event key \"queryStringParameters\" not set.")

        target = params.get("target")

        if not target:
            message_response.update(BAD_REQUEST_MESSAGE)
            raise BadRequestError(f"Expected event key \"queryStringParameters.target\" not set")

        target = target.lower()
        if target not in ['ecs', 'ec2', 'lambda']:
            message_response.update(BAD_REQUEST_MESSAGE)
            raise BadRequestError(F"Expected one of [\"ecs\", \"ecs\", \"lambda\"]. Got {target}.")

        downstream_faults = ""
        for _ in range(2):
            is_fault = int(random.randint(1, 100) > 70)
            downstream_faults += f"{is_fault}"

        # Generate a w3c traceparent header and inject into downstream
        # service calls
        headers = {
            "traceparent": f"00-{trace_id}-{span_id}-01",
            "content-type": "application/json",
            "x-fault": downstream_faults
        }

        resp = requests.get(f"{TARGET_BASE_URL}/{target}", headers = headers)

        client_body = resp.json()
        client_body["trace_id"] = trace_id
        client_body["span_id"] = span_id
        message_response.update({"statusCode": resp.status_code, "body": json.dumps(client_body)})

    except BadRequestError as e:
        print(e)
    except AuthorizationError as e:
        print(e)
    finally:
        end_time = time.time_ns()
        otlp_http_body = span_factory(trace_id, span_id, start_time, end_time, message_response["statusCode"], path, method)
        print(f"The span body = {otlp_http_body}")
        print(f"The message body = {json.dumps(message_response)}")
        trace_resp = requests.post(f"{HTTP_TRACE_GATEWAY_URL}/v1/traces", data = otlp_http_body, headers = {
        "Content-Type": "application/json"
        })

        # Observe that the error happened but don't interrupt client flow
        # Ideally, this would happen as a background thread so that it didn't
        # impact client latency as well
        if trace_resp.status_code != 200:
            print(f"Expected 200 status code. Received {resp.status_code} with body = {json.dumps(resp.json())}")

        return message_response



