variable "aws_region" {
  description = "Region of deployment"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "Ami ID of instance"
  type        = string
  default     = "ami-02b64aa047cb5edf5"
}

variable "instance_type" {
  description = "EC2 instance type for this environment"
  type        = string
  default     = "c7i-flex.large"
}

variable "environment" {
  description = "Name of this environment"
  type        = string
  default     = "production"
}
