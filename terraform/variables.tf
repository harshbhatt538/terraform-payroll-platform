variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "AZs to deploy resources into"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "payroll_admin"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "payroll_db"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for payroll documents"
  type        = string
  default     = "oceans-across-payroll-documents"
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI ID for eu-west-2"
  type        = string
  default     = "ami-0b72821e2f351e396"
}