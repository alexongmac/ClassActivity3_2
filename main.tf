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

module "github_oidc_bootstrap" {
  source = "./github-oidc-bootstrap"

  github_repository_username = "alexongmac"
  github_repository_name     = "ClassActivity3_2"
  github_oidc_role_name      = "alex-32-github-oidc-role"
}

# AmazonS3FullAccess (attached inside the module) grants no IAM permissions,
# but `terraform plan`/`apply` run by this same role need to read the OIDC
# provider and the role's own attached/inline policies to detect drift.
# This supplemental policy grants just those read-only IAM actions, scoped
# to this role and the GitHub OIDC provider.
resource "aws_iam_role_policy" "github_oidc_bootstrap_self_read" {
  #checkov:skip=CKV_AWS_355:iam:ListOpenIDConnectProviders is a list-only action with no resource-level ARN to scope to; all other statements are resource-scoped.
  name = "terraform-self-read"
  role = "alex-32-github-oidc-role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "OidcProviderList"
        Effect   = "Allow"
        Action   = "iam:ListOpenIDConnectProviders"
        Resource = "*"
      },
      {
        Sid      = "OidcProviderRead"
        Effect   = "Allow"
        Action   = "iam:GetOpenIDConnectProvider"
        Resource = "arn:aws:iam::255945442255:oidc-provider/token.actions.githubusercontent.com"
      },
      {
        Sid    = "GithubOidcRoleRead"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = "arn:aws:iam::255945442255:role/alex-32-github-oidc-role"
      }
    ]
  })

  depends_on = [module.github_oidc_bootstrap]
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