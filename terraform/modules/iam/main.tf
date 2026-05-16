# ─────────────────────────────────────────
# COMPANIES IAM ROLE
# ─────────────────────────────────────────

resource "aws_iam_role" "companies" {
  name = "companies-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Tenant = "companies"
  }
}

resource "aws_iam_policy" "companies_s3" {
  name        = "companies-s3-policy-${var.environment}"
  description = "Scoped S3 access for Companies tenant — prefix only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCompaniesPrefix"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}/companies/*",
          "arn:aws:s3:::${var.s3_bucket_name}"
        ]
        Condition = {
          StringLike = {
            "s3:prefix" = ["companies/*"]
          }
        }
      },
      {
        Sid    = "DenyOtherPrefixes"
        Effect = "Deny"
        Action = "s3:*"
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}/bureaus/*",
          "arn:aws:s3:::${var.s3_bucket_name}/employees/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "companies_secrets" {
  name        = "companies-secrets-policy-${var.environment}"
  description = "Allow Companies EC2 to read its own secrets only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCompaniesSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:oceans-across/companies/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "companies_s3" {
  role       = aws_iam_role.companies.name
  policy_arn = aws_iam_policy.companies_s3.arn
}

resource "aws_iam_role_policy_attachment" "companies_secrets" {
  role       = aws_iam_role.companies.name
  policy_arn = aws_iam_policy.companies_secrets.arn
}

resource "aws_iam_instance_profile" "companies" {
  name = "companies-profile-${var.environment}"
  role = aws_iam_role.companies.name
}


# ─────────────────────────────────────────
# BUREAUS IAM ROLE
# ─────────────────────────────────────────

resource "aws_iam_role" "bureaus" {
  name = "bureaus-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Tenant = "bureaus"
  }
}

resource "aws_iam_policy" "bureaus_s3" {
  name        = "bureaus-s3-policy-${var.environment}"
  description = "Scoped S3 access for Bureaus tenant — prefix only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBureausPrefix"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}/bureaus/*",
          "arn:aws:s3:::${var.s3_bucket_name}"
        ]
        Condition = {
          StringLike = {
            "s3:prefix" = ["bureaus/*"]
          }
        }
      },
      {
        Sid    = "DenyOtherPrefixes"
        Effect = "Deny"
        Action = "s3:*"
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}/companies/*",
          "arn:aws:s3:::${var.s3_bucket_name}/employees/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "bureaus_secrets" {
  name        = "bureaus-secrets-policy-${var.environment}"
  description = "Allow Bureaus EC2 to read its own secrets only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBureausSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:oceans-across/bureaus/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bureaus_s3" {
  role       = aws_iam_role.bureaus.name
  policy_arn = aws_iam_policy.bureaus_s3.arn
}

resource "aws_iam_role_policy_attachment" "bureaus_secrets" {
  role       = aws_iam_role.bureaus.name
  policy_arn = aws_iam_policy.bureaus_secrets.arn
}

resource "aws_iam_instance_profile" "bureaus" {
  name = "bureaus-profile-${var.environment}"
  role = aws_iam_role.bureaus.name
}


# ─────────────────────────────────────────
# EMPLOYEES IAM ROLE
# ─────────────────────────────────────────

resource "aws_iam_role" "employees" {
  name = "employees-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Tenant = "employees"
  }
}

resource "aws_iam_policy" "employees_s3" {
  name        = "employees-s3-policy-${var.environment}"
  description = "Scoped S3 access for Employees tenant — prefix only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEmployeesPrefix"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}/employees/*",
          "arn:aws:s3:::${var.s3_bucket_name}"
        ]
        Condition = {
          StringLike = {
            "s3:prefix" = ["employees/*"]
          }
        }
      },
      {
        Sid    = "DenyOtherPrefixes"
        Effect = "Deny"
        Action = "s3:*"
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}/companies/*",
          "arn:aws:s3:::${var.s3_bucket_name}/bureaus/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "employees_secrets" {
  name        = "employees-secrets-policy-${var.environment}"
  description = "Allow Employees EC2 to read its own secrets only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEmployeesSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:oceans-across/employees/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "employees_s3" {
  role       = aws_iam_role.employees.name
  policy_arn = aws_iam_policy.employees_s3.arn
}

resource "aws_iam_role_policy_attachment" "employees_secrets" {
  role       = aws_iam_role.employees.name
  policy_arn = aws_iam_policy.employees_secrets.arn
}

resource "aws_iam_instance_profile" "employees" {
  name = "employees-profile-${var.environment}"
  role = aws_iam_role.employees.name
}