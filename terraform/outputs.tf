output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "companies_instance_id" {
  description = "EC2 instance ID for Companies portal"
  value       = module.compute.companies_instance_id
}

output "bureaus_instance_id" {
  description = "EC2 instance ID for Bureaus portal"
  value       = module.compute.bureaus_instance_id
}

output "employees_instance_id" {
  description = "EC2 instance ID for Employees portal"
  value       = module.compute.employees_instance_id
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.rds_endpoint
  sensitive   = true
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.storage.bucket_name
}