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

