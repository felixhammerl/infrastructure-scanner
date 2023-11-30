data "aws_iam_policy_document" "step_list_iam_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "organizations:DescribeOrganization",
      "organizations:ListAccounts"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.scan_results.arn,
      "${aws_s3_bucket.scan_results.arn}/*"
    ]
  }
}

module "step_list" {
  source          = "./lambda"
  function_name   = "${local.service}-list"
  pkg_path        = "${path.root}/../build/steps/list"
  handler         = "src/handler/list.list_accounts"
  iam_policy_json = data.aws_iam_policy_document.step_list_iam_policy.json
}
