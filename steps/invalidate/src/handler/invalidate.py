import boto3
import os
import time


def invalidate_cloudfront(event, context):
    cf_distribution = os.getenv("CLOUDFRONT_DISTRIBUTION")
    millis = int(round(time.time() * 1000))

    client = boto3.client("cloudfront")
    response = client.create_invalidation(
        DistributionId=cf_distribution,
        InvalidationBatch={
            "Paths": {"Quantity": 1, "Items": ["/index.html"]},
            "CallerReference": f"{millis}",
        },
    )

    return response["Invalidation"]["Id"]
