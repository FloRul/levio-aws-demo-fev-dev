terraform {
  backend "s3" {
    bucket = "levio-aws-demo-fev-terraform"
    key    = "state/terraform_dev.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = "dev-dev"
      Terraform   = "true"
      Project     = "levio-aws-demo-fev-dev"
    }
  }
}


