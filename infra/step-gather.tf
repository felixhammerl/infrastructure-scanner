data "aws_iam_policy_document" "step_gather_iam_policy" {
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

module "step_gather" {
  source          = "./lambda"
  function_name   = "${local.service}-gather"
  pkg_path        = "${path.root}/../build/steps/gather"
  handler         = "src/handler/gather.gather_results"
  iam_policy_json = data.aws_iam_policy_document.step_gather_iam_policy.json
  env = {
    REPORT_BUCKET = aws_s3_bucket.scan_results.id
  }
}
