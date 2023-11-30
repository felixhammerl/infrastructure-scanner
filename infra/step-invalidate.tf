data "aws_iam_policy_document" "step_invalidate_iam_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }

  statement {
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [module.cloudfront.distribution_arn]
  }
}

module "step_invalidate" {
  source          = "./lambda"
  function_name   = "${local.service}-invalidate"
  pkg_path        = "${path.root}/../build/steps/invalidate"
  handler         = "src/handler/invalidate.invalidate_cloudfront"
  iam_policy_json = data.aws_iam_policy_document.step_invalidate_iam_policy.json
  env = {
    CLOUDFRONT_DISTRIBUTION = module.cloudfront.distribution_id
  }
}
