locals {
  route53_zone_name_normalized = trimsuffix(var.route53_zone_name, ".")
  route53_record_fqdn          = var.route53_record_name == "" ? local.route53_zone_name_normalized : "${var.route53_record_name}.${local.route53_zone_name_normalized}"
}

data "aws_route53_zone" "public" {
  count        = var.enable_https ? 1 : 0
  name         = "${local.route53_zone_name_normalized}."
  private_zone = false
}

resource "aws_acm_certificate" "public" {
  count             = var.enable_https ? 1 : 0
  domain_name       = var.acm_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-cert"
  })
}

resource "aws_route53_record" "acm_validation" {
  for_each = var.enable_https ? {
    for dvo in aws_acm_certificate.public[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  zone_id         = data.aws_route53_zone.public[0].zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
}

resource "aws_acm_certificate_validation" "public" {
  count                   = var.enable_https ? 1 : 0
  certificate_arn         = aws_acm_certificate.public[0].arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
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

module "security_groups" {
  source = "../../modules/security_groups"

  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  app_port                = var.app_port
  alb_ingress_cidr_blocks = var.alb_ingress_cidr_blocks
  common_tags             = local.common_tags
}

module "cloudwatch_logs" {
  source = "../../modules/cloudwatch_logs"

  project_name      = var.project_name
  environment       = var.environment
  retention_in_days = var.ecs_log_retention_in_days
  common_tags       = local.common_tags
}

module "ecs_cluster" {
  source = "../../modules/ecs_cluster"

  project_name              = var.project_name
  environment               = var.environment
  enable_container_insights = var.enable_container_insights
  common_tags               = local.common_tags
}

module "alb" {
  source = "../../modules/alb"

  name_prefix           = var.alb_name_prefix
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
  app_port              = var.app_port
  health_check_path     = var.health_check_path

  enable_https    = var.enable_https
  certificate_arn = var.enable_https ? aws_acm_certificate_validation.public[0].certificate_arn : null
  ssl_policy      = var.alb_ssl_policy

  common_tags = local.common_tags
}

resource "aws_route53_record" "app_alias" {
  count   = var.enable_https ? 1 : 0
  zone_id = data.aws_route53_zone.public[0].zone_id
  name    = local.route53_record_fqdn
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = var.route53_evaluate_target_health
  }
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  force_delete = var.ecr_force_delete
  common_tags  = local.common_tags
}

module "ecs_task_execution_role" {
  source = "../../modules/ecs_task_execution_role"

  name_prefix = var.ecs_name_prefix
  environment = var.environment
  common_tags = local.common_tags
}

module "ecs_task_definition" {
  source = "../../modules/ecs_task_definition"

  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  container_name        = var.container_name
  container_image       = "${module.ecr.repository_url}:${var.container_image_tag}"
  app_port              = var.app_port
  log_group_name        = module.cloudwatch_logs.ecs_app_log_group_name
  task_cpu              = var.task_cpu
  task_memory           = var.task_memory
  execution_role_arn    = module.ecs_task_execution_role.role_arn
  container_environment = var.container_environment
  common_tags           = local.common_tags
}

module "ecs_service" {
  source = "../../modules/ecs_service"

  project_name                      = var.project_name
  environment                       = var.environment
  cluster_arn                       = module.ecs_cluster.cluster_arn
  task_definition_arn               = module.ecs_task_definition.task_definition_arn
  container_name                    = var.container_name
  container_port                    = var.app_port
  target_group_arn                  = module.alb.target_group_arn
  private_subnet_ids                = module.vpc.private_subnet_ids
  ecs_tasks_security_group_id       = module.security_groups.ecs_tasks_security_group_id
  desired_count                     = var.service_desired_count
  enable_execute_command            = var.enable_execute_command
  health_check_grace_period_seconds = var.health_check_grace_period_seconds
  common_tags                       = local.common_tags

  depends_on = [module.alb]
}