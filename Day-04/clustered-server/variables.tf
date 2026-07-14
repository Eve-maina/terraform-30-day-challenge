variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-1"
}

variable "ami_id" {
  description = "AMI ID for the cluster instances (region specific — verify before use)"
  type        = string
  default     = "ami-08ae1035a3a101a88"
}

variable "instance_type" {
  description = "EC2 instance type for cluster instances"
  type        = string
  default     = "t3.micro"
}

variable "server_port" {
  description = "The port each instance listens on for HTTP traffic"
  type        = number
  default     = 8080
}

variable "alb_port" {
  description = "The port the load balancer listens on for incoming traffic"
  type        = number
  default     = 80
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 5
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets, one per AZ used"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}
