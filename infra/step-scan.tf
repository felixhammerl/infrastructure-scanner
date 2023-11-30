data "aws_iam_policy_document" "step_scan_task_policy" {
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
  statement {
    actions = ["sts:AssumeRole"]
    resources = [
      "arn:aws:iam::*:role/OrganizationAccountAccessRole"
    ]
  }
}

module "step_scan" {
  source          = "./ecs"
  module_name     = "${local.service}-scan"
  iam_policy_json = data.aws_iam_policy_document.step_scan_task_policy.json
}
