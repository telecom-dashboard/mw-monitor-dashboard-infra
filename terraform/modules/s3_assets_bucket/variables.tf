variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
}

variable "force_destroy" {
  description = "Whether to delete objects when destroying the bucket"
  type        = bool
  default     = false
}

variable "enable_versioning" {
  description = "Whether to enable S3 bucket versioning"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
