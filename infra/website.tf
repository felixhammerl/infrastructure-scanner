module "cloudfront" {
  source                   = "./cloudfront"
  module_name              = "${local.service}-website"
  domain_name              = "infrastructure.felixhammerl.com"
  hosted_zone_id           = "Z0456554X860JV75Q1CZ"
  authenticator_lambda_arn = module.website_authenticator.qualified_arn
}

data "aws_iam_policy_document" "website_authenticator_iam_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
}

module "website_authenticator" {
  source          = "./lambda"
  function_name   = "${local.service}-basic-auth"
  pkg_path        = "${path.root}/../build/edge/cloudfront"
  handler         = "src/handler/basic_auth.enforce_basic_auth"
  memory          = 128
  timeout         = 3
  iam_policy_json = data.aws_iam_policy_document.website_authenticator_iam_policy.json
}
