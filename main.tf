terraform {
  backend "s3" {
    bucket = "sctp-tfstate-ce13"
    key    = "alex-31-terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "alex_s3_buc" {
  bucket_prefix = "alex-31-bkt"

  tags = {
    Name        = "alex-31"
    Environment = "Dev-31"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

terraform {
  required_version = ">= 1.3.0"
}