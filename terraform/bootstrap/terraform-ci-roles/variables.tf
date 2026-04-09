variable "aws_region" {
  description = "AWS region for IAM resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
  default     = "heinzawhtoo"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "terraform-aws-ecs-multi-env-platform"
}

variable "github_branch" {
  description = "GitHub branch allowed to assume the role"
  type        = string
  default     = "main"
}

variable "dev_role_name" {
  description = "IAM role name for Terraform dev CI"
  type        = string
  default     = "github-actions-terraform-dev"
}

variable "prod_role_name" {
  description = "IAM role name for Terraform prod CI"
  type        = string
  default     = "github-actions-terraform-prod"
}

variable "tf_state_bucket_name" {
  description = "S3 bucket name for Terraform remote state"
  type        = string
}

variable "app_dev_role_name" {
  description = "IAM role name for GitHub Actions dev app image build/deploy"
  type        = string
  default     = "github-actions-app-dev"
}

variable "app_prod_role_name" {
  description = "IAM role name for GitHub Actions prod app image build/deploy"
  type        = string
  default     = "github-actions-app-prod"
}