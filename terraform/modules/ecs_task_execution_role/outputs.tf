output "role_name" {
  description = "ECS task execution role name"
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.this.arn
}