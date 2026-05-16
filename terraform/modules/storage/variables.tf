variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for payroll documents"
  type        = string
}

variable "companies_role_arn" {
  description = "ARN of the Companies IAM role"
  type        = string
}

variable "bureaus_role_arn" {
  description = "ARN of the Bureaus IAM role"
  type        = string
}

variable "employees_role_arn" {
  description = "ARN of the Employees IAM role"
  type        = string
}