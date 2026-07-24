variable "aws_region" {
  description = "Region to deploy the infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Cidr block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name to appear on the console"
  type        = string
  default     = "Demo VPC"

}