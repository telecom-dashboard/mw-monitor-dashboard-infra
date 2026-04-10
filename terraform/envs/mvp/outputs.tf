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

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "app_host_security_group_id" {
  description = "EC2 host security group ID"
  value       = module.ec2_security_group.security_group_id
}

output "app_instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2_host.instance_id
}

output "app_instance_elastic_ip" {
  description = "Elastic IP attached to the MVP app host"
  value       = module.ec2_host.elastic_ip
}

output "route53_record_fqdn" {
  description = "Route 53 record FQDN"
  value       = aws_route53_record.app.fqdn
}

output "application_url" {
  description = "Preferred MVP application URL"
  value       = "http://${local.route53_record_fqdn}"
}

output "api_base_url" {
  description = "MVP API base URL exposed through Nginx"
  value       = "http://${local.route53_record_fqdn}/api"
}

output "assets_bucket_name" {
  description = "S3 assets bucket name"
  value       = module.assets_bucket.bucket_name
}

output "assets_bucket_arn" {
  description = "S3 assets bucket ARN"
  value       = module.assets_bucket.bucket_arn
}

output "ec2_iam_role_arn" {
  description = "IAM role ARN attached to the EC2 host"
  value       = module.ec2_host.iam_role_arn
}

output "cpu_high_alarm_name" {
  description = "CloudWatch high CPU alarm name"
  value       = module.cloudwatch_ec2_basic.cpu_high_alarm_name
}

output "status_check_failed_alarm_name" {
  description = "CloudWatch status check failed alarm name"
  value       = module.cloudwatch_ec2_basic.status_check_failed_alarm_name
}
