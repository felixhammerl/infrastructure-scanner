# pyright: reportWildcardImportFromLibrary=false
from hamcrest import *
from base64 import b64encode

from src.handler.basic_auth import enforce_basic_auth


def test_should_redirect_when_no_header_present():
    event = {"Records": [{"cf": {"request": {"headers": {}}}}]}
    response = enforce_basic_auth(event, None)
    assert_that(response["status"], is_(equal_to("401")))
    assert_that(response["headers"]["www-authenticate"], is_(not_none()))


def test_should_redirect_when_wrong_credentials():
    event = {
        "Records": [
            {
                "cf": {
                    "request": {
                        "headers": {
                            "authorization": [
                                {
                                    "key": "Authorization",
                                    "value": "Basic thesecredentialsarewrong",
                                }
                            ]
                        }
                    }
                }
            }
        ]
    }
    response = enforce_basic_auth(event, None)
    assert_that(response["status"], is_(equal_to("401")))
    assert_that(response.get("www-authenticate"), is_(none()))


def test_should_continue_with_proper_headers():
    username = "username"
    password = "password"
    encoded_credentials = b64encode(f"{username}:{password}".encode()).decode()
    auth_string = f"Basic {encoded_credentials}"
    event = {
        "Records": [
            {
                "cf": {
                    "request": {
                        "headers": {
                            "authorization": [
                                {"key": "Authorization", "value": auth_string}
                            ]
                        }
                    }
                }
            }
        ]
    }
    excepted_request = event["Records"][0]["cf"]["request"]
    actual_request = enforce_basic_auth(event, None)
    assert_that(actual_request, is_(equal_to(excepted_request)))
