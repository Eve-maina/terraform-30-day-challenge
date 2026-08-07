variable "instance_name" {
    description = "Name tag for the ec2 instance"
    type = string
}

variable "ami_id" {
    description = "AMI ID of the instance"
    type = string
  
}

variable "instance_type" {
    description = "ec2 instance type"
    type = string
  
}