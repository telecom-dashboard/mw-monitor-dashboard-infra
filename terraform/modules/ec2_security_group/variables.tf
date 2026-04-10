variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "web_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access HTTP and HTTPS"
  type        = list(string)
}

variable "ssh_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access SSH"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
