output "terraform_dev_role_arn" {
  description = "IAM role ARN for Terraform dev CI"
  value       = aws_iam_role.terraform_dev.arn
}

output "terraform_prod_role_arn" {
  description = "IAM role ARN for Terraform prod CI"
  value       = aws_iam_role.terraform_prod.arn
}

output "app_dev_role_arn" {
  description = "IAM role ARN for GitHub Actions dev app image build/deploy"
  value       = aws_iam_role.app_dev.arn
}

output "app_prod_role_arn" {
  description = "IAM role ARN for GitHub Actions prod app image build/deploy"
  value       = aws_iam_role.app_prod.arn
}