# ─────────────────────────────────────────
# SECURITY GROUPS — one per tenant
# No inter-tenant traffic allowed
# ─────────────────────────────────────────

resource "aws_security_group" "companies" {
  name        = "companies-sg-${var.environment}"
  description = "Security group for Companies portal EC2"
  vpc_id      = var.vpc_id

  # Allow inbound app traffic from within VPC only
  ingress {
    description = "App port from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow outbound HTTPS for AWS API calls
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound to RDS
  egress {
    description = "PostgreSQL outbound"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name   = "companies-sg-${var.environment}"
    Tenant = "companies"
  }
}

resource "aws_security_group" "bureaus" {
  name        = "bureaus-sg-${var.environment}"
  description = "Security group for Bureaus portal EC2"
  vpc_id      = var.vpc_id

  ingress {
    description = "App port from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "PostgreSQL outbound"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name   = "bureaus-sg-${var.environment}"
    Tenant = "bureaus"
  }
}

resource "aws_security_group" "employees" {
  name        = "employees-sg-${var.environment}"
  description = "Security group for Employees portal EC2"
  vpc_id      = var.vpc_id

  ingress {
    description = "App port from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "PostgreSQL outbound"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name   = "employees-sg-${var.environment}"
    Tenant = "employees"
  }
}


# ─────────────────────────────────────────
# EC2 INSTANCES — one per tenant
# All in private subnets, no public IPs
# ─────────────────────────────────────────

resource "aws_instance" "companies" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_id              = var.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.companies.id]
  iam_instance_profile   = var.companies_profile

  # No public IP — only reachable within VPC
  associate_public_ip_address = false

  metadata_options {
    # Require IMDSv2 — prevents SSRF attacks from stealing instance credentials
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted   = true
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name   = "companies-ec2-${var.environment}"
    Tenant = "companies"
  }
}

resource "aws_instance" "bureaus" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_id              = var.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.bureaus.id]
  iam_instance_profile   = var.bureaus_profile

  associate_public_ip_address = false

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted   = true
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name   = "bureaus-ec2-${var.environment}"
    Tenant = "bureaus"
  }
}

resource "aws_instance" "employees" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_id              = var.private_subnet_ids[1]
  vpc_security_group_ids = [aws_security_group.employees.id]
  iam_instance_profile   = var.employees_profile

  associate_public_ip_address = false

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted   = true
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name   = "employees-ec2-${var.environment}"
    Tenant = "employees"
  }
}