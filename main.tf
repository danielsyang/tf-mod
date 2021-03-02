terraform {
  required_providers {
    aws = {
      version = ">= 2.7.0"
      source  = "hashicorp/aws"
    }
  }

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "my-own-local-company"
  }

  required_version = "~> 0.14"
}

provider "aws" {
  region = var.region
}

data "terraform_remote_state" "vpc" {
  backend = "remote"
  config = {
    organization = "my-own-local-company"
    workspaces = {
      name = "tf-test-dev"
    }
  }
}

module "security_group" {
  source      = "terraform-aws-modules/security-group/aws"
  name        = "security-test"
  description = "EC2 security group (terraform-managed)"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "ssh-tcp", "https-443-tcp"]
  egress_rules        = ["all-all"]
}

module "ec2_instances" {
  source        = "terraform-aws-modules/ec2-instance/aws"
  name          = "test-terraform-cloud"
  instance_type = "t2.micro"
  ami           = "ami-0885b1f6bd170450c"
  key_name      = "my-key2"

  vpc_security_group_ids = [module.security_group.this_security_group_id]
  subnet_id              = data.terraform_remote_state.vpc.outputs.public_subnets[0]
}
