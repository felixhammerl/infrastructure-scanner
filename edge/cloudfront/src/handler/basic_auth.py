from base64 import b64encode


def enforce_basic_auth(event, context):
    request = event["Records"][0]["cf"]["request"]
    headers = request["headers"]
    auth_header = headers.get("authorization")

    if not auth_header:
        return {
            "body": "Unauthorized",
            "headers": {
                "www-authenticate": [{"key": "WWW-Authenticate", "value": "Basic"}]
            },
            "status": "401",
            "statusDescription": "Unauthorized",
        }

    auth_header_value = auth_header[0].get("value")

    username = "username"
    password = "password"
    encoded_credentials = b64encode(f"{username}:{password}".encode()).decode()
    auth_string = f"Basic {encoded_credentials}"

    if auth_header_value != auth_string:
        return {
            "body": "Unauthorized",
            "status": "401",
            "statusDescription": "Unauthorized",
        }

    return request
