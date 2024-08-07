data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "website_files" {
  bucket_prefix = var.module_name
}

resource "aws_kms_key" "website_files_bucket_key" {
  description = "${var.module_name}-website-files-s3-bucket"
}

resource "aws_kms_key_policy" "website_files_bucket_key" {
  key_id = aws_kms_key.website_files_bucket_key.id
  policy = data.aws_iam_policy_document.website_files_bucket_key.json
}

data "aws_iam_policy_document" "website_files_bucket_key" {
  statement {
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
  statement {
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*"
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cf.arn]
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website_files_bucket_encryption" {
  bucket = aws_s3_bucket.website_files.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.website_files_bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_acl" "website_files_versioning_bucket_acl" {
  bucket     = aws_s3_bucket.website_files.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.website_files_ownership]
}

resource "aws_s3_bucket_ownership_controls" "website_files_ownership" {
  bucket = aws_s3_bucket.website_files.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


resource "aws_acm_certificate" "ssl_certificate" {
  domain_name = var.domain_name

  # DNS validation requires the domain nameservers to already be pointing to AWS
  validation_method         = "DNS"
  subject_alternative_names = ["*.${var.domain_name}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.ssl_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

resource "aws_acm_certificate_validation" "ssl_certificate_validation" {
  certificate_arn         = aws_acm_certificate.ssl_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_cloudfront_origin_access_control" "cloudfront_oac" {
  name                              = "${var.module_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

locals {
  origin_id = "${var.module_name}-origin-id"
}

resource "aws_cloudfront_distribution" "cf" {
  origin {
    domain_name              = aws_s3_bucket.website_files.bucket_regional_domain_name
    origin_id                = local.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.module_name}-CloudfrontDistribution"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.origin_id
    viewer_protocol_policy = "redirect-to-https"

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400

    forwarded_values {
      query_string = false
      headers = [
        "Origin",
        "Content-Type"
      ]

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = var.authenticator_lambda_arn
    }
  }

  ordered_cache_behavior {
    path_pattern = "*"

    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.origin_id
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = var.authenticator_lambda_arn
    }
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  aliases = [var.domain_name]

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.ssl_certificate_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

}

resource "aws_s3_bucket_policy" "website_files" {
  bucket = aws_s3_bucket.website_files.id
  policy = data.aws_iam_policy_document.website_files.json
}

data "aws_iam_policy_document" "website_files" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website_files.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cf.arn]
    }
  }
}

resource "aws_route53_record" "root-a" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cf.domain_name
    zone_id                = aws_cloudfront_distribution.cf.hosted_zone_id
    evaluate_target_health = false
  }
}
