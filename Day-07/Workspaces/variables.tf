variable "aws_region" {
    description = "Region of deployment"
    type = string
    default = "us-east-1"
}

variable "ami_id" {
    description = "Ami ID of instance"
    type = string
    default = "ami-02b64aa047cb5edf5" 
}

variable "instance_type" {
    description = "Instance type of instances"
    type = map(string)
    default = {
        dev = "t3.micro"
        staging = "t3.small"
        production = "c7i-flex.large"
    }
  
}