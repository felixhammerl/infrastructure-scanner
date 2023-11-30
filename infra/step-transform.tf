data "aws_iam_policy_document" "step_transform_iam_policy" {
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
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*"
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
      "${aws_s3_bucket.scan_results.arn}/*",
      module.cloudfront.s3_bucket_arn,
      "${module.cloudfront.s3_bucket_arn}/*"
    ]
  }
}

module "step_transform" {
  source          = "./lambda"
  function_name   = "${local.service}-transform"
  pkg_path        = "${path.root}/../build/steps/transform"
  handler         = "src/handler/transform.transform_report"
  iam_policy_json = data.aws_iam_policy_document.step_transform_iam_policy.json
  env = {
    REPORT_BUCKET  = aws_s3_bucket.scan_results.id
    WEBSITE_BUCKET = module.cloudfront.s3_bucket_id
  }
}
