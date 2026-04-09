output "ecs_app_log_group_name" {
  description = "ECS app log group name"
  value       = aws_cloudwatch_log_group.ecs_app.name
}

output "ecs_app_log_group_arn" {
  description = "ECS app log group ARN"
  value       = aws_cloudwatch_log_group.ecs_app.arn
}