import boto3


def list_accounts(event, context):
    client = boto3.client("organizations")
    response = client.list_accounts()
    accounts = response.get("Accounts", [])
    while "NextToken" in response:
        response = client.list_accounts(NextToken=response["NextToken"])
        accounts += response.get("Accounts", [])

    accounts = [
        account["Id"] for account in accounts if account.get("Status") == "ACTIVE"
    ]

    payer_account_id = boto3.client("sts").get_caller_identity().get("Account")
    ignored_account_ids = [payer_account_id]

    return list(set(accounts) - set(ignored_account_ids))
