variable "aws_region" {
  description = "AWS region for the MVP environment"
  type        = string
}

variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones used for public subnets"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets. Leave empty for the low-cost MVP layout."
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT gateway"
  type        = bool
  default     = false
}

variable "web_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the public web ports"
  type        = list(string)
}

variable "ssh_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to the instance"
  type        = list(string)
  default     = []
}

variable "route53_zone_name" {
  description = "Public Route 53 hosted zone name"
  type        = string
}

variable "route53_record_name" {
  description = "Record label to create in Route 53. Use empty string for the zone apex."
  type        = string
  default     = ""
}

variable "deploy_target_tag_key" {
  description = "Stable EC2 tag key used by the MVP app repo to target the host for SSM deploys"
  type        = string
  default     = "DeployTarget"
}

variable "deploy_target_tag_value" {
  description = "Stable EC2 tag value used by the MVP app repo to target the host for SSM deploys"
  type        = string
  default     = "nw-monitor-dashboard-mvp-app-host"
}

variable "enable_https" {
  description = "Whether to provision HTTPS on the MVP EC2 host with Let's Encrypt."
  type        = bool
  default     = false
}

variable "letsencrypt_email" {
  description = "Email address used for Let's Encrypt registration when HTTPS is enabled."
  type        = string
  default     = ""
}

variable "app_port" {
  description = "Internal backend application port on the EC2 host"
  type        = number
  default     = 8000
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
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
  description = "Enable detailed CloudWatch monitoring on the EC2 instance"
  type        = bool
  default     = false
}

variable "assets_bucket_name" {
  description = "Globally unique S3 bucket name for static files and uploaded assets"
  type        = string
}

variable "assets_bucket_force_destroy" {
  description = "Whether to delete objects when destroying the assets bucket"
  type        = bool
  default     = false
}

variable "assets_bucket_versioning_enabled" {
  description = "Whether to enable bucket versioning"
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "CloudWatch alarm action ARNs such as SNS topics"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "CloudWatch OK action ARNs such as SNS topics"
  type        = list(string)
  default     = []
}

variable "cpu_utilization_threshold" {
  description = "CPU utilization percentage threshold for the EC2 alarm"
  type        = number
  default     = 80
}

variable "postgres_db_name" {
  description = "Initial PostgreSQL database name bootstrapped on the EC2 host"
  type        = string
  default     = "app"
}

variable "postgres_app_user" {
  description = "Initial PostgreSQL application user name bootstrapped on the EC2 host"
  type        = string
  default     = "app"
}

variable "app_systemd_service_name" {
  description = "Systemd service name reserved for the backend application"
  type        = string
  default     = "saas-app"
}
