variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "container_name" {
  description = "Container name"
  type        = string
}

variable "container_image" {
  description = "Full container image URI"
  type        = string
}

variable "app_port" {
  description = "Application port"
  type        = number
}

variable "log_group_name" {
  description = "CloudWatch log group name for application logs"
  type        = string
}

variable "task_cpu" {
  description = "Task CPU units for Fargate"
  type        = number
}

variable "task_memory" {
  description = "Task memory (MiB) for Fargate"
  type        = number
}

variable "execution_role_arn" {
  description = "ECS task execution role ARN"
  type        = string
}

variable "container_environment" {
  description = "Environment variables passed into the container"
  type        = map(string)
  default     = {}
}

variable "cpu_architecture" {
  description = "CPU architecture for the runtime platform"
  type        = string
  default     = "X86_64"
}

variable "operating_system_family" {
  description = "Operating system family for the runtime platform"
  type        = string
  default     = "LINUX"
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}