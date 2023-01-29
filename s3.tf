resource "random_string" "s3_unique_key" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

# ------------------------------
# S3 private bucket
# ------------------------------
resource "aws_s3_bucket" "private" {
  bucket = "${var.project}-${var.environment}-private-bucket-${random_string.s3_unique_key.result}"
}

resource "aws_s3_bucket_versioning" "s3_private_bucket" {
  bucket = aws_s3_bucket.private.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_private_bucket" {
  bucket = aws_s3_bucket.private.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.private.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------
# S3 public bucket
# ------------------------------
resource "aws_s3_bucket" "public" {
  bucket = "${var.project}-${var.environment}-public-bucket-${random_string.s3_unique_key.result}"
}

resource "aws_s3_bucket_acl" "public-s3-bucket" {
  bucket = aws_s3_bucket.public.id
  acl    = "public-read"
}

resource "aws_s3_bucket_cors_configuration" "public-s3-bucket" {
  bucket = aws_s3_bucket.public.id

  cors_rule {
    allowed_origins = ["https://example.com"]
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}
