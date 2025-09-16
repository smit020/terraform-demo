# static_site.tf
############################
# S3 Website (public) + CloudFront custom origin (Website Endpoint)
############################

locals {
  bucket_name = "fashionassit1" # must be globally unique
  dist_dir    = "${path.module}/dist"
  dist_files  = fileset(local.dist_dir, "**")

  content_types = {
    html  = "text/html"
    css   = "text/css"
    js    = "application/javascript"
    mjs   = "application/javascript"
    json  = "application/json"
    map   = "application/json"
    png   = "image/png"
    jpg   = "image/jpeg"
    jpeg  = "image/jpeg"
    gif   = "image/gif"
    svg   = "image/svg+xml"
    webp  = "image/webp"
    ico   = "image/x-icon"
    woff  = "font/woff"
    woff2 = "font/woff2"
    ttf   = "font/ttf"
    otf   = "font/otf"
    wasm  = "application/wasm"
    xml   = "application/xml"
    pdf   = "application/pdf"
  }
}

# S3 bucket (Website hosting, public read for website endpoint)
resource "aws_s3_bucket" "site" {
  bucket        = local.bucket_name
  force_destroy = true
  tags          = merge(var.tags, { Name = local.bucket_name })
}

# Enforce bucket-owner object ownership (disables ACLs)
resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

# Relax block-public-access on this bucket for website endpoint usage
resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 static website config (index/error documents)
resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  index_document { suffix = "index.html" }
  error_document { key = "error.html" }
}

# Public-read policy so S3 website endpoint can serve files
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.site.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid : "PublicReadForWebsite",
      Effect : "Allow",
      Principal : "*",
      Action : ["s3:GetObject"],
      Resource : "${aws_s3_bucket.site.arn}/*"
    }]
  })
}

# Upload the dist/ folder
resource "aws_s3_object" "dist" {
  for_each = { for f in local.dist_files : f => f }

  bucket = aws_s3_bucket.site.id
  key    = each.value
  source = "${local.dist_dir}/${each.value}"
  etag   = filemd5("${local.dist_dir}/${each.value}")

  # Set Content-Encoding when serving precompressed assets
  content_encoding = endswith(each.value, ".br") ? "br" : (endswith(each.value, ".gz") ? "gzip" : null)

  # Derive content-type after stripping compression suffix
  content_type = lookup(
    local.content_types,
    element(
      split(".", replace(replace(basename(each.value), ".br", ""), ".gz", "")),
      length(split(".", replace(replace(basename(each.value), ".br", ""), ".gz", ""))) - 1
    ),
    "binary/octet-stream"
  )

  # Cache policy: HTML entry points no-cache; hashed assets long cache; others short
  cache_control = contains(["index.html", "error.html"], lower(replace(replace(basename(each.value), ".br", ""), ".gz", ""))) ? "no-cache, no-store, must-revalidate" : (can(regex("[.-][a-f0-9]{8,}", basename(each.value))) ? "public, max-age=31536000, immutable" : "public, max-age=300")
}

# CloudFront in front of S3 Website Endpoint (Custom Origin)
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket_website_configuration.site.website_endpoint
    origin_id   = "s3-website-origin"

    # Website endpoints are only supported as Custom Origins
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-website-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  # SPA-style fallback (optional): map 403s to index.html
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate { cloudfront_default_certificate = true }

  tags = var.tags
}

# Outputs
output "s3_website_endpoint" { value = aws_s3_bucket_website_configuration.site.website_endpoint }
output "cloudfront_domain" { value = aws_cloudfront_distribution.cdn.domain_name }
