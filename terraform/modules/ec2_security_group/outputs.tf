output "security_group_id" {
  description = "EC2 app host security group ID"
  value       = aws_security_group.app_host.id
}
