# ─────────────────────────────────────────
# PROVIDERS
# Monitoring uses same provider as main infra
# ─────────────────────────────────────────

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

# ─────────────────────────────────────────
# VARIABLES
# ─────────────────────────────────────────

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "alert_email" {
  description = "Email address for critical alerts"
  type        = string
}

variable "companies_instance_id" {
  description = "EC2 instance ID for Companies portal"
  type        = string
}

variable "bureaus_instance_id" {
  description = "EC2 instance ID for Bureaus portal"
  type        = string
}

variable "employees_instance_id" {
  description = "EC2 instance ID for Employees portal"
  type        = string
}

variable "rds_instance_identifier" {
  description = "RDS instance identifier"
  type        = string
}


# ─────────────────────────────────────────
# SNS TOPIC — Critical alerts
# Single topic, email subscription
# ─────────────────────────────────────────

resource "aws_sns_topic" "critical_alerts" {
  name = "oceans-across-critical-alerts-${var.environment}"

  tags = {
    Name        = "oceans-across-critical-alerts-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}


# ─────────────────────────────────────────
# CLOUDWATCH LOG GROUPS
# Separate log group per service
# 30 day retention — balances cost vs audit
# ─────────────────────────────────────────

resource "aws_cloudwatch_log_group" "companies" {
  name              = "/oceans-across/companies/${var.environment}"
  retention_in_days = 30

  tags = {
    Service     = "companies"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "bureaus" {
  name              = "/oceans-across/bureaus/${var.environment}"
  retention_in_days = 30

  tags = {
    Service     = "bureaus"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "employees" {
  name              = "/oceans-across/employees/${var.environment}"
  retention_in_days = 30

  tags = {
    Service     = "employees"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "rds" {
  name              = "/oceans-across/rds/${var.environment}"
  retention_in_days = 30

  tags = {
    Service     = "rds"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "infrastructure" {
  name              = "/oceans-across/infrastructure/${var.environment}"
  retention_in_days = 90

  # Infrastructure logs kept longer for compliance and audit
  tags = {
    Service     = "infrastructure"
    Environment = var.environment
  }
}


# ─────────────────────────────────────────
# EC2 CPU ALARMS — one per tenant instance
# Triggers at 80% CPU for 2 consecutive periods
# ─────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "companies_cpu" {
  alarm_name          = "oceans-across-companies-cpu-high-${var.environment}"
  alarm_description   = "Companies portal EC2 CPU utilisation above 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = var.companies_instance_id
  }

  alarm_actions = [aws_sns_topic.critical_alerts.arn]
  ok_actions    = [aws_sns_topic.critical_alerts.arn]

  tags = {
    Tenant      = "companies"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "bureaus_cpu" {
  alarm_name          = "oceans-across-bureaus-cpu-high-${var.environment}"
  alarm_description   = "Bureaus portal EC2 CPU utilisation above 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = var.bureaus_instance_id
  }

  alarm_actions = [aws_sns_topic.critical_alerts.arn]
  ok_actions    = [aws_sns_topic.critical_alerts.arn]

  tags = {
    Tenant      = "bureaus"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "employees_cpu" {
  alarm_name          = "oceans-across-employees-cpu-high-${var.environment}"
  alarm_description   = "Employees portal EC2 CPU utilisation above 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = var.employees_instance_id
  }

  alarm_actions = [aws_sns_topic.critical_alerts.arn]
  ok_actions    = [aws_sns_topic.critical_alerts.arn]

  tags = {
    Tenant      = "employees"
    Environment = var.environment
  }
}


# ─────────────────────────────────────────
# RDS ALARMS
# Connection threshold + storage + CPU
# ─────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "oceans-across-rds-connections-high-${var.environment}"
  alarm_description   = "RDS connection count above threshold — possible connection leak"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_identifier
  }

  alarm_actions = [aws_sns_topic.critical_alerts.arn]
  ok_actions    = [aws_sns_topic.critical_alerts.arn]

  tags = {
    Service     = "rds"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "oceans-across-rds-cpu-high-${var.environment}"
  alarm_description   = "RDS CPU utilisation above 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_identifier
  }

  alarm_actions = [aws_sns_topic.critical_alerts.arn]
  ok_actions    = [aws_sns_topic.critical_alerts.arn]

  tags = {
    Service     = "rds"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "oceans-across-rds-storage-low-${var.environment}"
  alarm_description   = "RDS free storage below 5GB — risk of database failure"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5000000000 # 5GB in bytes
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_identifier
  }

  alarm_actions = [aws_sns_topic.critical_alerts.arn]

  tags = {
    Service     = "rds"
    Environment = var.environment
  }
}

# ─────────────────────────────────────────
# RDS PUBLIC ACCESS ALARM
# Detects if RDS is ever made publicly
# accessible — critical security event
# ─────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "rds_public_access" {
  name        = "oceans-across-rds-public-access-${var.environment}"
  description = "Fires if RDS instance is modified to be publicly accessible"

  event_pattern = jsonencode({
    source      = ["aws.rds"]
    detail-type = ["RDS DB Instance Event"]
    detail = {
      EventID = ["RDS-EVENT-0088"]
    }
  })

  tags = {
    Service     = "rds"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_event_target" "rds_public_access_sns" {
  rule      = aws_cloudwatch_event_rule.rds_public_access.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.critical_alerts.arn
}