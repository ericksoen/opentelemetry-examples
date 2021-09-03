import time
import json

def handler(event, context):
    time.sleep(1)
    return {
        "statusCode": 200,
        "isBase64Encoded": False,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"message": "hello-world"}),
    }

if __name__ == "__main__":
    handler(None, None)