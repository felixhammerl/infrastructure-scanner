resource "aws_s3_bucket" "website_files" {
  bucket_prefix = var.module_name
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website_files_bucket_encryption" {
  bucket = aws_s3_bucket.website_files.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
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

resource "aws_cloudfront_origin_access_identity" "cloudfront_oai" {
  comment = "${var.module_name}-OAI"
}

locals {
  origin_id = "${var.module_name}-origin-id"
}

resource "aws_cloudfront_distribution" "cf" {
  origin {
    domain_name = aws_s3_bucket.website_files.bucket_regional_domain_name
    origin_id   = local.origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cloudfront_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.module_name}-CloudfrontDistribution"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id
    viewer_protocol_policy = "redirect-to-https"

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = var.authenticator_lambda_arn
    }
  }

  ordered_cache_behavior {
    path_pattern           = "*"

    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
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
  policy = jsonencode({
    "Version" : "2008-10-17",
    "Id" : "CloudfrontAccess to Website Files",
    "Statement" : [
      {
        "Sid" : "1",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "${aws_cloudfront_origin_access_identity.cloudfront_oai.iam_arn}"
        },
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.website_files.id}/*"
      }
    ]
  })

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
