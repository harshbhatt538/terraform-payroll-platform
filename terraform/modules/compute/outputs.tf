output "companies_instance_id" {
  description = "Instance ID for Companies portal EC2"
  value       = aws_instance.companies.id
}

output "bureaus_instance_id" {
  description = "Instance ID for Bureaus portal EC2"
  value       = aws_instance.bureaus.id
}

output "employees_instance_id" {
  description = "Instance ID for Employees portal EC2"
  value       = aws_instance.employees.id
}

output "tenant_security_group_ids" {
  description = "All tenant security group IDs - passed to RDS to allow inbound 5432"
  value = [
    aws_security_group.companies.id,
    aws_security_group.bureaus.id,
    aws_security_group.employees.id
  ]
}

output "companies_sg_id" {
  description = "Security group ID for Companies EC2"
  value       = aws_security_group.companies.id
}

output "bureaus_sg_id" {
  description = "Security group ID for Bureaus EC2"
  value       = aws_security_group.bureaus.id
}

output "employees_sg_id" {
  description = "Security group ID for Employees EC2"
  value       = aws_security_group.employees.id
}