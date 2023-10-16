from itertools import groupby
from operator import itemgetter
from copy import deepcopy
import json
import boto3
import os
import datetime

from iteration_utilities import unique_everseen


def gather_results(event, context):
    bucket = os.getenv("REPORT_BUCKET")
    date = datetime.date.today().strftime("%Y/%m/%d")

    s3 = boto3.client("s3")
    response = s3.list_objects(
        Bucket=bucket,
        Prefix=date,
    )

    keys = [content["Key"] for content in response["Contents"]]

    account_reports = []
    for key in keys:
        result = s3.get_object(Bucket=bucket, Key=key)
        text = result["Body"].read().decode()
        report = json.loads(text)
        account_reports.append(
            {
                "account": key.removeprefix(f"{date}/").removesuffix(".json"),
                "report": report,
            }
        )

    master_report = deepcopy(account_reports[0]["report"])
    master_report = list(
        unique_everseen(
            [
                {
                    k: v
                    for k, v in elem.items()
                    if k in ["plugin", "category", "title", "description"]
                }
                for elem in master_report
            ]
        )
    )
    for plugin in master_report:
        plugin["reports"] = {
            report["account"]: [
                {
                    k: v
                    for k, v in elem.items()
                    if k in ["resource", "region", "status", "message"]
                }
                for elem in report["report"]
                if elem["plugin"] == plugin["plugin"]
            ]
            for report in account_reports
        }

    master_report_by_category = {
        k: list(v) for k, v in groupby(master_report, key=itemgetter("category"))
    }

    result = s3.put_object(
        Bucket=bucket,
        Key=f"{date}/report.json",
        Body=json.dumps(master_report_by_category).encode(),
    )

    return master_report_by_category
