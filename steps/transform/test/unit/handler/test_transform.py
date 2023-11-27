# pyright: reportWildcardImportFromLibrary=false
import json
from hamcrest import *
from moto import mock_s3
import boto3
import datetime
import os
from unittest import mock


from src.handler.transform import transform_report
from test.fixture import read_fixture

REPORT_BUCKET = "some_report_bucket"
WEBSITE_BUCKET = "some_website_bucket"


@mock_s3
@mock.patch.dict(os.environ, {"REPORT_BUCKET": REPORT_BUCKET})
@mock.patch.dict(os.environ, {"WEBSITE_BUCKET": WEBSITE_BUCKET})
def test_should_transform_report_to_html():
    s3 = boto3.client("s3")
    s3.create_bucket(
        ACL="private", Bucket=REPORT_BUCKET, ObjectOwnership="BucketOwnerPreferred",
        CreateBucketConfiguration={
            "LocationConstraint": "foo-bar-bla",
        },
    )

    s3.create_bucket(
        ACL="private", Bucket=WEBSITE_BUCKET, ObjectOwnership="BucketOwnerPreferred",
        CreateBucketConfiguration={
            "LocationConstraint": "foo-bar-bla",
        },
    )

    scan_path = datetime.date.today().strftime("%Y/%m/%d")
    report_from_fixture = read_fixture(filename="report.json")
    s3.put_object(
        Body=report_from_fixture.encode(),
        Bucket=REPORT_BUCKET,
        Key=f"{scan_path}/report.json",
    )

    transform_report(context=None, event=None)

    result = s3.get_object(Bucket=WEBSITE_BUCKET, Key=f"index.html")
    html_from_s3 = result["Body"].read().decode()

    html_from_fixture = read_fixture(filename="index.html")

    with open("index.html", "w") as text_file:
        text_file.write(html_from_s3)

    assert_that(html_from_s3, is_(equal_to(html_from_fixture)))
