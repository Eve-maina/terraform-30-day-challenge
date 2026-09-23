variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

# --- count demo: a plain list, resources are tracked by position ---
variable "count_users" {
  description = "IAM users created with count (remove the middle one to see the index shift)"
  type        = list(string)
  default     = ["dave", "erin", "frank"]
}

# --- for_each demo: a map, resources are tracked by key ---
variable "users" {
  description = "IAM users created with for_each, keyed by username"
  type = map(object({
    department = string
  }))
  default = {
    alice = { department = "engineering" }
    bob   = { department = "marketing" }
    carol = { department = "engineering" }
  }
}

# --- conditional demo #1: turn a resource on/off ---
variable "enable_audit_logs" {
  description = "Create the audit CloudWatch log group (stands in for enable_autoscaling)"
  type        = bool
  default     = true
}

# --- conditional demo #2: vary a value by environment ---
variable "environment" {
  description = "Environment name: dev or production"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "production"], var.environment)
    error_message = "environment must be either \"dev\" or \"production\"."
  }
}
