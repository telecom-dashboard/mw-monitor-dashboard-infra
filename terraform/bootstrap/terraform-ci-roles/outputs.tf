output "terraform_dev_role_arn" {
  description = "IAM role ARN for Terraform dev CI"
  value       = var.enable_legacy_terraform_dev_role ? aws_iam_role.terraform_dev[0].arn : null
}

output "terraform_prod_role_arn" {
  description = "IAM role ARN for Terraform prod CI"
  value       = var.enable_legacy_terraform_prod_role ? aws_iam_role.terraform_prod[0].arn : null
}

output "app_dev_role_arn" {
  description = "IAM role ARN for GitHub Actions dev app image build/deploy"
  value       = var.enable_legacy_app_dev_role ? aws_iam_role.app_dev[0].arn : null
}

output "app_prod_role_arn" {
  description = "IAM role ARN for GitHub Actions prod app image build/deploy"
  value       = var.enable_legacy_app_prod_role ? aws_iam_role.app_prod[0].arn : null
}

output "mvp_app_deploy_role_arn" {
  description = "IAM role ARN for GitHub Actions MVP app deploy from telecom-dashboard/mw-dashboard-app"
  value       = aws_iam_role.mvp_app_deploy.arn
}

output "business_terraform_dev_role_arn" {
  description = "IAM role ARN for business repo Terraform dev CI"
  value       = aws_iam_role.business_terraform_dev.arn
}

output "business_terraform_prod_role_arn" {
  description = "IAM role ARN for business repo Terraform prod CI"
  value       = aws_iam_role.business_terraform_prod.arn
}

output "business_app_dev_role_arn" {
  description = "IAM role ARN for business repo app dev image build/deploy"
  value       = aws_iam_role.business_app_dev.arn
}

output "business_app_prod_role_arn" {
  description = "IAM role ARN for business repo app prod image build/deploy"
  value       = aws_iam_role.business_app_prod.arn
}
