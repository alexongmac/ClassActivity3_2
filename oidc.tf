# Existing GitHub OIDC identity provider already registered in this account.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_oidc" {
  name = "alex-32-github-oidc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = data.aws_iam_openid_connect_provider.github.arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Allow workflow runs triggered by pull_request events on this repo only.
            # GitHub sometimes appends immutable numeric IDs to the owner/repo
            # (e.g. "repo:alexongmac@54748360/ClassActivity3_2@1383224553:pull_request"),
            # so wildcard those segments instead of matching the plain names exactly.
            "token.actions.githubusercontent.com:sub" = "repo:alexongmac*/ClassActivity3_2*:pull_request"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_oidc_s3" {
  name = "s3-bucket-management"
  role = aws_iam_role.github_oidc.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketLevel"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:PutBucketTagging",
          "s3:PutBucketVersioning",
          "s3:GetBucketVersioning",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutLifecycleConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetBucketTagging",
          "s3:GetBucketLocation",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy"
        ]
        Resource = "arn:aws:s3:::alex-32-bkt*"
      },
      {
        Sid    = "S3ObjectLevel"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::alex-32-bkt*/*"
      },
      {
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::sctp-tfstate-ce13",
          "arn:aws:s3:::sctp-tfstate-ce13/alex_s3/*"
        ]
      },
      {
        Sid    = "OidcProviderRead"
        Effect = "Allow"
        Action = [
          "iam:ListOpenIDConnectProviders",
          "iam:GetOpenIDConnectProvider"
        ]
        # These actions do not support resource-level restriction to a single provider.
        Resource = "*"
      },
      {
        Sid    = "GithubOidcRoleRead"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies"
        ]
        Resource = "arn:aws:iam::*:role/alex-32-github-oidc-role"
      }
    ]
  })
}
