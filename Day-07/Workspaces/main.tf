terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "kalibee-terraform-state-2026"
    key = "terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt = true 
  }
  
}

provider "aws" {
    region = var.aws_region

}

resource "aws_instance" "web" {
    ami = var.ami_id 
    instance_type = var.instance_type[terraform.workspace]

    tags = {
      Name = "web-${terraform.workspace}"
      Environment = terraform.workspace
    }
  
}

