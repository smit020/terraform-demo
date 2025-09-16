def lambda_handler(event, context):
    body = {
        "message": "playerlambda invoked",
        "input": event.get("body") if isinstance(event, dict) else None
    }
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": __import__('json').dumps(body)
    }
