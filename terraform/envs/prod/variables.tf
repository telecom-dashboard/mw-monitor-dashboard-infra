variable "aws_region" {
  description = "AWS region for the prod environment"
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
  description = "VPC CIDR block"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT gateway"
  type        = bool
  default     = true
}

variable "app_port" {
  description = "Application port for ECS tasks"
  type        = number
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
}

variable "enable_https" {
  description = "Whether to create ACM, HTTPS listener, and Route 53 alias record"
  type        = bool
  default     = false
}

variable "route53_zone_name" {
  description = "Public Route 53 hosted zone name"
  type        = string
  default     = ""
}

variable "route53_record_name" {
  description = "Record label to create in Route 53. Use empty string for the zone apex."
  type        = string
  default     = ""
}

variable "acm_domain_name" {
  description = "Domain name to request in ACM"
  type        = string
  default     = ""
}

variable "alb_ssl_policy" {
  description = "SSL policy for the ALB HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "route53_evaluate_target_health" {
  description = "Whether Route 53 should evaluate ALB target health for the alias record"
  type        = bool
  default     = true
}

variable "ecs_log_retention_in_days" {
  description = "CloudWatch log retention in days"
  type        = number
}

variable "enable_container_insights" {
  description = "Enable ECS container insights"
  type        = bool
  default     = true
}

variable "alb_name_prefix" {
  description = "Short prefix used for ALB resources with AWS name length limits"
  type        = string
  default     = "tfecs"
}

variable "ecs_name_prefix" {
  description = "Short prefix used for ECS-related IAM/resource names with AWS length limits"
  type        = string
  default     = "tfecs"
}

variable "ecr_force_delete" {
  description = "Whether to force delete the ECR repository if it still contains images"
  type        = bool
  default     = false
}

variable "container_name" {
  description = "Container name used in the task definition"
  type        = string
  default     = "app"
}

variable "container_image_tag" {
  description = "Bootstrap image tag used only for the initial Terraform task definition. The app deploy workflow will later publish SHA-tagged images and update the running service."
  type        = string
  default     = "bootstrap"
}

variable "task_cpu" {
  description = "Task CPU units for Fargate"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Task memory in MiB for Fargate"
  type        = number
  default     = 512
}

variable "container_environment" {
  description = "Environment variables passed into the container"
  type        = map(string)
  default     = {}
}

variable "service_desired_count" {
  description = "Bootstrap desired count used only when the ECS service is first created. After that, the app deploy workflow owns the live running count."
  type        = number
  default     = 0
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for the service"
  type        = bool
  default     = false
}

variable "health_check_grace_period_seconds" {
  description = "Grace period before ALB health checks affect ECS service stability"
  type        = number
  default     = 60
}