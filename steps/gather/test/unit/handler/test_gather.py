# pyright: reportWildcardImportFromLibrary=false
import json
from hamcrest import *
from moto import mock_s3
import boto3
import datetime
import os
from unittest import mock


from src.handler.gather import gather_results
from test.fixture import read_test_scan_reports

BUCKET = "some_bucket"


@mock_s3
@mock.patch.dict(os.environ, {"REPORT_BUCKET": BUCKET})
def test_should_create_master_report():
    scan_path = datetime.date.today().strftime("%Y/%m/%d")

    reports = read_test_scan_reports()
    s3 = boto3.client("s3")
    s3.create_bucket(
        ACL="private", Bucket=BUCKET, ObjectOwnership="BucketOwnerPreferred"
    )

    for report in reports:
        s3.put_object(
            Body=report["content"], Bucket=BUCKET, Key=f"{scan_path}/{report['file']}"
        )

    master_report = gather_results(context=None, event=None)

    assert_that(master_report, is_not(empty()))

    result = s3.get_object(Bucket=BUCKET, Key=f"{scan_path}/report.json")
    text = result["Body"].read().decode()
    report_from_s3 = json.loads(text)

    assert_that(report_from_s3, is_(equal_to(master_report)))

    for category, plugins in master_report.items():
        assert_that(category, is_(instance_of(str)))
        for plugin in plugins:
            for key in plugin.keys():
                assert_that(key, is_in(["plugin", "category", "title", "description", "reports"]))

            for account, findings in plugin["reports"].items():
                assert_that(account, is_(instance_of(str)))
                for finding in findings:
                    for finding_property in finding.keys():
                        assert_that(finding_property, is_in(["resource", "region", "status", "message"]))


