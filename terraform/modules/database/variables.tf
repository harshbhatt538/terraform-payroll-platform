variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for RDS subnet group"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "db_username" {
  description = "RDS master username"
  type        = string
}

variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "allowed_security_group_ids" {
  description = "List of EC2 security group IDs allowed to connect to RDS on port 5432"
  type        = list(string)
}