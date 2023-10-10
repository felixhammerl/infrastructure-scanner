data "archive_file" "source" {
  type        = "zip"
  source_dir  = var.pkg_path
  output_path = "${var.pkg_path}.zip"

}

resource "aws_s3_bucket" "bucket" {
  bucket_prefix = var.function_name
  force_destroy = true
}

resource "aws_s3_object" "file_upload" {
  bucket = aws_s3_bucket.bucket.id
  key    = var.function_name
  source = data.archive_file.source.output_path
  etag   = filemd5(data.archive_file.source.output_path)
}
