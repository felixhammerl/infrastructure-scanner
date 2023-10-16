resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  handler          = var.handler
  runtime          = "python3.11"
  s3_bucket        = aws_s3_bucket.bucket.bucket
  s3_key           = aws_s3_object.file_upload.id
  role             = aws_iam_role.lambda-exec-role.arn
  timeout          = 300
  memory_size      = 512
  publish          = true
  source_code_hash = filebase64sha256(data.archive_file.source.output_path)
  environment {
    variables = var.env
  }
}
