resource "aws_s3_bucket" "scan_results" {
  bucket_prefix = "${local.service}-scan-results"
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
