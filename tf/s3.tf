
# + Bucket S3
resource "aws_s3_bucket" "mi_bucket" {
  bucket = "nmr-bucket"
  force_destroy = true

  tags = {
    Name        = "nmr-bucket"
    Environment = "Dev"
  }
}

# Configurar el acceso público para el bucket
resource "aws_s3_bucket_public_access_block" "bucket_public_block" {
  bucket = aws_s3_bucket.mi_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  depends_on = [aws_s3_bucket.mi_bucket]
}

# Aplicar la política de acceso pública al bucket
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.mi_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.mi_bucket.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.bucket_public_block]
}

# Configurar mi bucket como un sitio web estático
resource "aws_s3_bucket_website_configuration" "s3_pagina" {
  bucket = aws_s3_bucket.mi_bucket.id

  index_document {
    suffix = "index.html"
  }
}