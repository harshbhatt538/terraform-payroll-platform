variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs to deploy EC2 instances into"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  type        = string
}

variable "companies_profile" {
  description = "IAM instance profile name for Companies EC2"
  type        = string
}

variable "bureaus_profile" {
  description = "IAM instance profile name for Bureaus EC2"
  type        = string
}

variable "employees_profile" {
  description = "IAM instance profile name for Employees EC2"
  type        = string
}