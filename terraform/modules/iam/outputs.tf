output "companies_role_arn" {
  description = "ARN of the Companies IAM role"
  value       = aws_iam_role.companies.arn
}

output "bureaus_role_arn" {
  description = "ARN of the Bureaus IAM role"
  value       = aws_iam_role.bureaus.arn
}

output "employees_role_arn" {
  description = "ARN of the Employees IAM role"
  value       = aws_iam_role.employees.arn
}

output "companies_instance_profile" {
  description = "Instance profile name for Companies EC2"
  value       = aws_iam_instance_profile.companies.name
}

output "bureaus_instance_profile" {
  description = "Instance profile name for Bureaus EC2"
  value       = aws_iam_instance_profile.bureaus.name
}

output "employees_instance_profile" {
  description = "Instance profile name for Employees EC2"
  value       = aws_iam_instance_profile.employees.name
}