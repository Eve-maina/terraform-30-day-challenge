terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "webserver_cluster" {
  source = "git::https://github.com/Eve-maina/terraform-30-day-challenge.git//Day-09/modules/services/web-cluster?ref=main"

  cluster_name  = "webservers-dev"
  ami_id        = "ami-0332d564d76dbd8d6"
  vpc_id        = "vpc-00a2b39126fe6afd7"
  subnet_ids    = ["subnet-02b28c5efbb6beab6", "subnet-04dd599b34549794e"]
  instance_type = "t3.small"
  min_size      = 2
  max_size      = 4 
  server_port = 80
}