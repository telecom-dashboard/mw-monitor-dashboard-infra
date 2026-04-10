variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_id" {
  description = "EC2 instance ID"
  type        = string
}

variable "cpu_utilization_threshold" {
  description = "CPU utilization percentage threshold for the alarm"
  type        = number
  default     = 80
}

variable "alarm_actions" {
  description = "Alarm action ARNs such as SNS topics"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "OK action ARNs such as SNS topics"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
