output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "elastic_ip" {
  description = "Elastic IP address attached to the instance"
  value       = aws_eip.this.public_ip
}

output "elastic_ip_allocation_id" {
  description = "Elastic IP allocation ID"
  value       = aws_eip.this.id
}

output "iam_role_name" {
  description = "IAM role name attached to the EC2 instance"
  value       = aws_iam_role.instance.name
}

output "iam_role_arn" {
  description = "IAM role ARN attached to the EC2 instance"
  value       = aws_iam_role.instance.arn
}
