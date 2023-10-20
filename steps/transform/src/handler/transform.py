import json
import boto3
import os
import datetime
import dominate
from dominate.tags import *
from dominate import document


def transform_report(event, context):
    report_bucket = os.getenv("REPORT_BUCKET")
    website_bucket = os.getenv("WEBSITE_BUCKET")

    date = datetime.date.today().strftime("%Y/%m/%d")
    filename = "report.json"
    key = f"{date}/{filename}"

    s3 = boto3.client("s3")
    result = s3.get_object(Bucket=report_bucket, Key=key)
    text = result["Body"].read().decode()
    report = json.loads(text)

    page = generate_html(report=report)
    result = s3.put_object(
        Bucket=website_bucket,
        Key="index.html",
        Body=page.encode(),
    )


def generate_html(report) -> str:
    doc = document(title="Cloud Security Posture Report")

    with doc.head:
        meta(charset="UTF-8")
        meta(name="viewport", content="width=device-width, initial-scale=1.0")
        link(
            href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css",
            rel="stylesheet",
        )

    doc.body.set_attribute("class", "bg-gray-100 p-2 max-w-2xl mx-auto")
    with doc.body:
        for category, items in report.items():
            with details(cls="mt-8"):
                summary(
                    h2(category, cls="ml-2 cursor-pointer text-3xl font-bold inline")
                )
                with ul():
                    for item in items:
                        with li(cls="mt-4"):
                            with details():
                                summary(
                                    h3(
                                        item["title"],
                                        cls="ml-2 cursor-pointer inline text-xl font-bold",
                                    )
                                )
                                p(item["description"])
                                with ul():
                                    for account, findings in item["reports"].items():
                                        with li(cls="my-2"):
                                            with details():
                                                summary(
                                                    h4(
                                                        strong("Account ID: "),
                                                        account,
                                                        cls="ml-2 cursor-pointer inline",
                                                    )
                                                )
                                                with ul():
                                                    for finding in findings:
                                                        with li(cls="my-2"):
                                                            p(
                                                                strong("Resource: "),
                                                                finding["resource"],
                                                                br(),
                                                                strong("Region: "),
                                                                finding["region"],
                                                                br(),
                                                                strong("Status: "),
                                                                finding["status"],
                                                                br(),
                                                                strong("Message: "),
                                                                finding["message"],
                                                            )

    return doc.render()
