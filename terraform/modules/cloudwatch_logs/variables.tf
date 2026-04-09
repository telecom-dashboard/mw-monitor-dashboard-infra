variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "retention_in_days" {
  description = "Log retention in days"
  type        = number
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}