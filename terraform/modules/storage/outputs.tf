output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.payroll_documents.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.payroll_documents.arn
}

output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.payroll_documents.id
}