locals {
  service = "infrastructure-scanner"
  region  = "us-east-1"
}

terraform {
  backend "s3" {
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = local.region
}

resource "aws_s3_bucket" "scan_results" {
  bucket_prefix = "${local.service}-scan-results"
}

resource "aws_s3_bucket" "website_bucket" {
  bucket_prefix = "${local.service}-website"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "scan_results_bucket_encryption" {
  bucket = aws_s3_bucket.scan_results.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_acl" "scan_results_versioning_bucket_acl" {
  bucket     = aws_s3_bucket.scan_results.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.scan_results_ownership]
}

resource "aws_s3_bucket_ownership_controls" "scan_results_ownership" {
  bucket = aws_s3_bucket.scan_results.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


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
  pkg_path        = "${path.root}/../build/list"
  handler         = "src/handler/list.list_accounts"
  iam_policy_json = data.aws_iam_policy_document.step_list_iam_policy.json
}

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
  pkg_path        = "${path.root}/../build/gather"
  handler         = "src/handler/gather.gather_results"
  iam_policy_json = data.aws_iam_policy_document.step_gather_iam_policy.json
  env = {
    REPORT_BUCKET = aws_s3_bucket.scan_results.id
  }
}

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
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.scan_results.arn,
      "${aws_s3_bucket.scan_results.arn}/*",
      aws_s3_bucket.website_bucket.arn,
      "${aws_s3_bucket.website_bucket.arn}/*"
    ]
  }
}

module "step_transform" {
  source          = "./lambda"
  function_name   = "${local.service}-transform"
  pkg_path        = "${path.root}/../build/transform"
  handler         = "src/handler/transform.transform_report"
  iam_policy_json = data.aws_iam_policy_document.step_transform_iam_policy.json
  env = {
    REPORT_BUCKET  = aws_s3_bucket.scan_results.id
    WEBSITE_BUCKET = aws_s3_bucket.website_bucket.id
  }
}

module "sfn" {
  source      = "./sfn"
  module_name = local.service
  step_list   = module.step_list.arn
  step_scan = {
    cluster_arn         = module.step_scan.cluster_arn
    task_arn            = module.step_scan.task_arn
    task_container_name = module.step_scan.container_name
    security_groups     = module.step_scan.security_groups
    subnets             = module.step_scan.subnets
    assign_public_ip    = module.step_scan.assign_public_ip
  }
  step_gather    = module.step_gather.arn
  step_transform = module.step_transform.arn
  ecs_task_roles = [
    module.step_scan.task_role_arn,
    module.step_scan.exec_role_arn
  ]
  results_bucket = aws_s3_bucket.scan_results.id
}
