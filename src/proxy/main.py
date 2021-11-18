import requests
import json
import os

TARGET_BASE_URL = os.getenv("TARGET_BASE_URL")

BAD_REQUEST_MESSAGE = {
            "statusCode": 400,
            "headers": {
                "content-type": "application/json",
            },
            "body": json.dumps({"message": "bad request"})
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
    
    resp = requests.get(f"{TARGET_BASE_URL}/{target}")

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(resp.json())
    }