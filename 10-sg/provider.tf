terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.33.0"
    }
  }

  backend "s3" {
    bucket = "remote-state-aws-88b-dev"
    key    = "terraform-eks-sg"
    region = "us-east-1"
    encrypt = true
    use_lockfile = true
  }
}


provider "aws" {
   region = "us-east-1"
}