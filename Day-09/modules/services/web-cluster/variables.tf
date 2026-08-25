variable "cluster_name" {
  description = "The name to use for all cluster resources"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the cluster"
  type        = string
  default     = "t2.micro"
}

variable "min_size" {
  description = "Minimum number of EC2 instances in the ASG"
  type        = number
}

variable "max_size" {
  description = "Maximum number of EC2 instances in the ASG"
  type        = number
}

variable "server_port" {
  description = "Port the server uses for HTTP"
  type        = number
  default     = 8080
}

variable "ami_id" {
  description = "AMI ID to launch cluster instances from"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where cluster resources will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ASG and ALB"
  type        = list(string)
}