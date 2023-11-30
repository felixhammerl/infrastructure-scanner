output "s3_bucket_id" {
  value = aws_s3_bucket.website_files.id
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.website_files.arn
}

output "distribution_id" {
  value = aws_cloudfront_distribution.cf.id
}

output "distribution_arn" {
  value = aws_cloudfront_distribution.cf.arn
}
