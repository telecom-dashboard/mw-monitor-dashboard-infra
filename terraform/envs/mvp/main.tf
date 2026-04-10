data "aws_route53_zone" "public" {
  name         = "${local.route53_zone_name_normalized}."
  private_zone = false
}

module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  common_tags          = local.common_tags
}

module "ec2_security_group" {
  source = "../../modules/ec2_security_group"

  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  web_ingress_cidr_blocks = var.web_ingress_cidr_blocks
  ssh_ingress_cidr_blocks = var.ssh_ingress_cidr_blocks
  common_tags             = local.common_tags
}

module "assets_bucket" {
  source = "../../modules/s3_assets_bucket"

  project_name      = var.project_name
  environment       = var.environment
  bucket_name       = var.assets_bucket_name
  force_destroy     = var.assets_bucket_force_destroy
  enable_versioning = var.assets_bucket_versioning_enabled
  common_tags       = local.common_tags
}

module "ec2_host" {
  source = "../../modules/ec2_host"

  project_name                = var.project_name
  environment                 = var.environment
  subnet_id                   = module.vpc.public_subnet_ids[0]
  security_group_id           = module.ec2_security_group.security_group_id
  instance_type               = var.instance_type
  ami_id                      = var.ami_id
  key_name                    = var.key_name
  root_volume_size            = var.root_volume_size
  enable_detailed_monitoring  = var.enable_detailed_monitoring
  assets_bucket_arn           = module.assets_bucket.bucket_arn
  user_data                   = templatefile("${path.module}/user_data.sh.tftpl", {
    app_domain_name         = local.route53_record_fqdn
    app_port                = var.app_port
    app_systemd_service_name = var.app_systemd_service_name
    assets_bucket_name      = module.assets_bucket.bucket_name
    postgres_app_password   = var.postgres_app_password
    postgres_app_user       = var.postgres_app_user
    postgres_db_name        = var.postgres_db_name
  })
  common_tags                 = local.common_tags
}

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = local.route53_record_fqdn
  type    = "A"
  ttl     = 300
  records = [module.ec2_host.elastic_ip]
}

module "cloudwatch_ec2_basic" {
  source = "../../modules/cloudwatch_ec2_basic"

  project_name              = var.project_name
  environment               = var.environment
  instance_id               = module.ec2_host.instance_id
  cpu_utilization_threshold = var.cpu_utilization_threshold
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  common_tags               = local.common_tags
}
