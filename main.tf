terraform {
  # NOTE: "sctp-tfstate-ce13" is a pre-existing, shared course-managed state
  # bucket (provisioned out of band, not by this configuration). This backend
  # will fail on `terraform init` in any environment where that bucket does
  # not already exist.
  backend "s3" {
    bucket = "sctp-tfstate-ce13"
    key    = "alex_s3/alex-32-terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "alex_s3_buc" {
  #checkov:skip=CKV_AWS_144:Cross-region replication not needed for class demo
  #checkov:skip=CKV_AWS_145:SSE-S3 default encryption is sufficient for demo
  #checkov:skip=CKV_AWS_18:Access logging not needed for class demo
  #checkov:skip=CKV2_AWS_62:Event notifications not needed for class demo
  bucket_prefix = "alex-32-bkt"

  tags = {
    Name        = "alex-32"
    Environment = "Dev-32"
  }
}

module "github_oidc_bootstrap" {
  source = "./github-oidc-bootstrap"

  github_repository_username = "alexongmac"
  github_repository_name     = "ClassActivity3_2"
  github_oidc_role_name      = "alex-32-github-oidc-role"
}

resource "aws_s3_bucket_public_access_block" "alex_s3_buc" {
  bucket                  = aws_s3_bucket.alex_s3_buc.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "alex_s3_buc" {
  bucket = aws_s3_bucket.alex_s3_buc.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alex_s3_buc" {
  bucket = aws_s3_bucket.alex_s3_buc.id
  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
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