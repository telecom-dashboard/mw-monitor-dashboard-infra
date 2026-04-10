variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID for the EC2 instance"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID applied to the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami_id" {
  description = "AMI ID. Leave empty to use the latest Ubuntu 24.04 LTS public AMI from SSM."
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Optional EC2 key pair name"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 20
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for the EC2 instance"
  type        = bool
  default     = false
}

variable "assets_bucket_arn" {
  description = "ARN of the S3 bucket the instance should be able to access"
  type        = string
}

variable "user_data" {
  description = "User data script used to bootstrap the host"
  type        = string
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
