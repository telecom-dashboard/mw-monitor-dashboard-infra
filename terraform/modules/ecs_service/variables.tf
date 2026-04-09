variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_arn" {
  description = "ECS cluster ARN"
  type        = string
}

variable "task_definition_arn" {
  description = "ECS task definition ARN"
  type        = string
}

variable "container_name" {
  description = "Container name used by the ECS service load balancer block"
  type        = string
}

variable "container_port" {
  description = "Container port used by the ECS service load balancer block"
  type        = number
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ecs_tasks_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "desired_count" {
  description = "Desired number of running tasks"
  type        = number
  default     = 1
}

variable "assign_public_ip" {
  description = "Whether to assign public IPs to ECS tasks"
  type        = bool
  default     = false
}

variable "platform_version" {
  description = "Fargate platform version"
  type        = string
  default     = "LATEST"
}

variable "enable_execute_command" {
  description = "Enable ECS Exec"
  type        = bool
  default     = false
}

variable "health_check_grace_period_seconds" {
  description = "Grace period before ALB health checks affect service stability"
  type        = number
  default     = 60
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower limit on healthy tasks during deployment"
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "Upper limit on running tasks during deployment"
  type        = number
  default     = 200
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}