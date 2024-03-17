# pyright: reportWildcardImportFromLibrary=false
import json
from hamcrest import *
from moto import mock_aws
import boto3
import pytest
import os
from unittest import mock


from src.handler.invalidate import invalidate_cloudfront


@pytest.fixture()
def with_mock_cf_distro():
    with mock_aws():
        cf = boto3.client("cloudfront")

        cf_distribution = cf.create_distribution(
            DistributionConfig=dict(
                CallerReference="firstOne",
                Aliases=dict(Quantity=1, Items=["mydomain.com"]),
                DefaultRootObject="index.html",
                Comment="Test distribution",
                Enabled=True,
                Origins=dict(
                    Quantity=1,
                    Items=[
                        dict(
                            Id="1",
                            DomainName="mydomain.com.s3.amazonaws.com",
                            S3OriginConfig=dict(OriginAccessIdentity=""),
                        )
                    ],
                ),
                DefaultCacheBehavior=dict(
                    TargetOriginId="1",
                    ViewerProtocolPolicy="redirect-to-https",
                    TrustedSigners=dict(Quantity=0, Enabled=False),
                    ForwardedValues=dict(
                        Cookies={"Forward": "all"},
                        Headers=dict(Quantity=0),
                        QueryString=False,
                        QueryStringCacheKeys=dict(Quantity=0),
                    ),
                    MinTTL=1000,
                ),
            )
        )["Distribution"]["Id"]
        k = mock.patch.dict(os.environ, {"CLOUDFRONT_DISTRIBUTION": cf_distribution})
        k.start()

        yield

        k.stop()


def test_should_create_master_report(with_mock_cf_distro):
    invalidation_id = invalidate_cloudfront(context=None, event=None)

    assert_that(invalidation_id, is_(not_none()))
