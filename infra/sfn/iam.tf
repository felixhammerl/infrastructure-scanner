resource "aws_iam_role" "sfn" {
  name               = "${var.module_name}-sfn-excecution"
  assume_role_policy = data.aws_iam_policy_document.sfn-assume-role.json
}

data "aws_region" "sfn_region" {}

data "aws_iam_policy_document" "sfn-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.${data.aws_region.sfn_region.name}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "sfn-execution" {
  role       = aws_iam_role.sfn.name
  policy_arn = aws_iam_policy.sfn-execution.arn
}

resource "aws_iam_policy" "sfn-execution" {
  name   = "${var.module_name}-sfn-excecution"
  policy = data.aws_iam_policy_document.sfn-execution.json
}

data "aws_iam_policy_document" "sfn-execution" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "states:StartExecution",
      "states:DescribeExecution",
      "states:StopExecution",
    ]
    resources = ["*"]
  }
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = ["*"]
  }
  statement {
    actions   = ["ecs:RunTask"]
    resources = ["*"]
  }
  statement {
    actions   = ["iam:PassRole"]
    resources = var.ecs_task_roles
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "sfn-execution-cw-full-access" {
  role       = aws_iam_role.sfn.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchEventsFullAccess"
}
