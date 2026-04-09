output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "common_tags" {
  description = "Common tags"
  value       = local.common_tags
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = module.security_groups.alb_security_group_id
}

output "ecs_tasks_security_group_id" {
  description = "ECS tasks security group ID"
  value       = module.security_groups.ecs_tasks_security_group_id
}

output "ecs_app_log_group_name" {
  description = "ECS app log group name"
  value       = module.cloudwatch_logs.ecs_app_log_group_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs_cluster.cluster_name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = module.ecs_cluster.cluster_arn
}

output "alb_arn" {
  description = "ALB ARN"
  value       = module.alb.alb_arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = module.alb.target_group_arn
}

output "alb_zone_id" {
  description = "ALB Route 53 zone ID"
  value       = module.alb.alb_zone_id
}

output "https_listener_arn" {
  description = "HTTPS listener ARN"
  value       = module.alb.https_listener_arn
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = var.enable_https ? aws_acm_certificate.public[0].arn : null
}

output "route53_alias_fqdn" {
  description = "Route 53 application alias FQDN"
  value       = var.enable_https ? local.route53_record_fqdn : null
}

output "application_url" {
  description = "Preferred application URL"
  value       = var.enable_https ? "https://${local.route53_record_fqdn}" : "http://${module.alb.alb_dns_name}"
}

output "http_listener_arn" {
  description = "HTTP listener ARN"
  value       = module.alb.http_listener_arn
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = module.ecr.repository_name
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = module.ecr.repository_arn
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "ecs_task_execution_role_name" {
  description = "ECS task execution role name"
  value       = module.ecs_task_execution_role.role_name
}

output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = module.ecs_task_execution_role.role_arn
}

output "ecs_task_definition_arn" {
  description = "ECS task definition ARN"
  value       = module.ecs_task_definition.task_definition_arn
}

output "ecs_task_definition_family" {
  description = "ECS task definition family"
  value       = module.ecs_task_definition.task_definition_family
}

output "ecs_task_definition_revision" {
  description = "ECS task definition revision"
  value       = module.ecs_task_definition.task_definition_revision
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs_service.service_name
}

output "ecs_service_arn" {
  description = "ECS service ARN"
  value       = module.ecs_service.service_arn
}