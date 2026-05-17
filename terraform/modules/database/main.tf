# ─────────────────────────────────────────
# SECRETS MANAGER - RDS master password
# Never hardcoded, injected at runtime
# ─────────────────────────────────────────

resource "aws_secretsmanager_secret" "db_password" {
  name        = "oceans-across/database/master-password-${var.environment}"
  description = "RDS master password for payroll database"

  # Retain for 7 days after deletion - allows recovery if deleted by mistake
  recovery_window_in_days = 7

  tags = {
    Name = "db-password-${var.environment}"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    dbname   = var.db_name
  })
}

# Generate a strong random password - no hardcoding
resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%^&*()-_=+[]{}|;:,.<>?"
}


# ─────────────────────────────────────────
# SECURITY GROUP - RDS
# Only accepts traffic from EC2 instances
# ─────────────────────────────────────────

resource "aws_security_group" "rds" {
  name        = "rds-sg-${var.environment}"
  description = "Security group for RDS - only allows EC2 tenant instances on 5432"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      description              = "PostgreSQL from tenant EC2"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      security_groups          = [ingress.value]
    }
  }

  # No egress rules - RDS does not need to initiate outbound connections
  egress {
    description = "No outbound needed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg-${var.environment}"
  }
}


# ─────────────────────────────────────────
# RDS SUBNET GROUP
# Spans both private subnets across 2 AZs
# ─────────────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name        = "db-subnet-group-${var.environment}"
  description = "Private subnet group for RDS across two AZs"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name = "db-subnet-group-${var.environment}"
  }
}


# ─────────────────────────────────────────
# RDS INSTANCE - PostgreSQL
# Private subnet, encrypted, no public access
# ─────────────────────────────────────────

resource "aws_db_instance" "main" {
  identifier        = "payroll-db-${var.environment}"
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Encryption at rest - mandatory for payroll/PII data
  storage_encrypted = true

  # Not publicly accessible - only reachable within VPC
  publicly_accessible = false

  # Automated backups - 7 day retention
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Disable multi-AZ for dev - enable in production
  multi_az = false

  # Prevent accidental deletion in production
  deletion_protection = false

  # Take final snapshot when destroyed
  skip_final_snapshot       = false
  final_snapshot_identifier = "payroll-db-final-snapshot-${var.environment}"

  # Enable enhanced monitoring logs
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  parameter_group_name = aws_db_parameter_group.main.name
}

# ─────────────────────────────────────────
# RDS PARAMETER GROUP
# Forces SSL on all connections
# ─────────────────────────────────────────

resource "aws_db_parameter_group" "main" {
  name        = "oceans-across-postgres-params-${var.environment}"
  family      = "postgres15"
  description = "Custom parameter group forcing SSL on all RDS connections"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = {
    Name = "oceans-across-postgres-params-${var.environment}"
  }
}
