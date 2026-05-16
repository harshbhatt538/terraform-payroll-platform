module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment
}

module "iam" {
  source         = "./modules/iam"
  environment    = var.environment
  s3_bucket_name = var.s3_bucket_name
}

module "compute" {
  source               = "./modules/compute"
  environment          = var.environment
  ami_id               = var.ami_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = var.vpc_cidr
  companies_profile    = module.iam.companies_instance_profile
  bureaus_profile      = module.iam.bureaus_instance_profile
  employees_profile    = module.iam.employees_instance_profile
}

module "database" {
  source                    = "./modules/database"
  environment               = var.environment
  private_subnet_ids        = module.vpc.private_subnet_ids
  vpc_id                    = module.vpc.vpc_id
  db_username               = var.db_username
  db_name                   = var.db_name
  allowed_security_group_ids = module.compute.tenant_security_group_ids
}

module "storage" {
  source         = "./modules/storage"
  environment    = var.environment
  s3_bucket_name = var.s3_bucket_name
  companies_role_arn = module.iam.companies_role_arn
  bureaus_role_arn   = module.iam.bureaus_role_arn
  employees_role_arn = module.iam.employees_role_arn
}