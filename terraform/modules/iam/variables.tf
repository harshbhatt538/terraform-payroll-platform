variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket to scope access to"
  type        = string
}