# ─────────────────────────────────────────
# S3 BUCKET
# Versioning enabled, all public access blocked
# ─────────────────────────────────────────

resource "aws_s3_bucket" "payroll_documents" {
  bucket = "${var.s3_bucket_name}-${var.environment}"

  tags = {
    Name        = "${var.s3_bucket_name}-${var.environment}"
    Environment = var.environment
  }
}

# Block all public access - no exceptions
resource "aws_s3_bucket_public_access_block" "payroll_documents" {
  bucket = aws_s3_bucket.payroll_documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning - required by task, also important for payroll audit trail
resource "aws_s3_bucket_versioning" "payroll_documents" {
  bucket = aws_s3_bucket.payroll_documents.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption at rest using AES-256
resource "aws_s3_bucket_server_side_encryption_configuration" "payroll_documents" {
  bucket = aws_s3_bucket.payroll_documents.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Lifecycle policy - move older versions to cheaper storage
resource "aws_s3_bucket_lifecycle_configuration" "payroll_documents" {
  bucket = aws_s3_bucket.payroll_documents.id

  rule {
    id     = "archive-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

# ─────────────────────────────────────────
# BUCKET POLICY
# Enforces prefix-level tenant isolation
# Even if IAM logic fails, this is the
# second enforcement boundary
# ─────────────────────────────────────────

resource "aws_s3_bucket_policy" "payroll_documents" {
  bucket = aws_s3_bucket.payroll_documents.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # Companies role - can only access companies/ prefix
      {
        Sid    = "AllowCompaniesPrefix"
        Effect = "Allow"
        Principal = {
          AWS = var.companies_role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}-${var.environment}/companies/*"
      },
      {
        Sid    = "AllowCompaniesListBucket"
        Effect = "Allow"
        Principal = {
          AWS = var.companies_role_arn
        }
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}-${var.environment}"
        Condition = {
          StringLike = {
            "s3:prefix" = ["companies/*"]
          }
        }
      },

      # Bureaus role - can only access bureaus/ prefix
      {
        Sid    = "AllowBureausPrefix"
        Effect = "Allow"
        Principal = {
          AWS = var.bureaus_role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}-${var.environment}/bureaus/*"
      },
      {
        Sid    = "AllowBureausListBucket"
        Effect = "Allow"
        Principal = {
          AWS = var.bureaus_role_arn
        }
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}-${var.environment}"
        Condition = {
          StringLike = {
            "s3:prefix" = ["bureaus/*"]
          }
        }
      },

      # Employees role - can only access employees/ prefix
      {
        Sid    = "AllowEmployeesPrefix"
        Effect = "Allow"
        Principal = {
          AWS = var.employees_role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}-${var.environment}/employees/*"
      },
      {
        Sid    = "AllowEmployeesListBucket"
        Effect = "Allow"
        Principal = {
          AWS = var.employees_role_arn
        }
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}-${var.environment}"
        Condition = {
          StringLike = {
            "s3:prefix" = ["employees/*"]
          }
        }
      },

      # Deny any request not using HTTPS - enforces encryption in transit
      {
        Sid       = "DenyNonHTTPS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}-${var.environment}",
          "arn:aws:s3:::${var.s3_bucket_name}-${var.environment}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.payroll_documents]
}
