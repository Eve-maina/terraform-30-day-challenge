terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }

  backend "s3" {
    bucket       = "kalibee-terraform-state-bucket"
    key          = "dev/services/ec2-instance/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"

}

module "ec2_instance" {
  source = "../../../../modules/services/ec2-instance"

  instance_name = "prod_server"
  instance_type = "t3.small"
  ami_id = "ami-0bdc7d025135d7b49"

}
