variable "aws_region" {
  description = "AWS region for the Terraform backend bucket"
  type        = string
  default     = "ap-southeast-1"
}

variable "bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
}