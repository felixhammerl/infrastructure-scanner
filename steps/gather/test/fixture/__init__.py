from pathlib import Path


def read_test_scan_reports():
    report_files = [
        "123123123123.json",
        "456456456456.json",
        "789789789789.json",
        "report.json",
    ]

    reports = [
        {"file": report, "content": open(Path(__file__).with_name(report)).read()}
        for report in report_files
    ]
    return reports
