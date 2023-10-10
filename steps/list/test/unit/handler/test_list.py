# pyright: reportWildcardImportFromLibrary=false
import json
from hamcrest import *
from moto import mock_organizations, mock_sts
import boto3

from src.handler.list import list_accounts


@mock_organizations
@mock_sts
def test_should_list_accouns():
    client = boto3.client("organizations")
    client.create_organization(FeatureSet="ALL")
    client.create_account(Email="fred.foo@example.com", AccountName="fredfoo")
    client.create_account(Email="ben.bar@example.com", AccountName="benbar")
    client.create_account(Email="r.u.sirius@example.com", AccountName="rusirius")

    accounts = list_accounts(context=None, event=None)

    assert_that(len(accounts), is_(equal_to(3)))
