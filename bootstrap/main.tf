data "aws_caller_identity" "current" {}

locals {
  owner = split("/", var.github_repo)[0]
  repo  = split("/", var.github_repo)[1]

  # GitHub sends the newer ID-based subject; the plain form is kept as a fallback.
  allowed_subjects = [
    "repo:${local.owner}@${var.github_repo_ids.owner_id}/${local.repo}@${var.github_repo_ids.repo_id}:environment:*",
    "repo:${var.github_repo}:environment:*",
  ]
}

# ---------------------------------------------------------------------------
# State bucket
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  # lifecycle {
    force_destroy = true # holds every tenant's state - never delete by accident
  # }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# GitHub Actions OIDC trust
# ---------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.allowed_subjects
    }
  }
}

resource "aws_iam_role" "github" {
  name               = var.github_role_name
  description        = "GitHub Actions - auth0-terraform state access"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

data "aws_iam_policy_document" "state_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["auth0/*"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/auth0/*"]
  }
}

resource "aws_iam_role_policy" "state_access" {
  name   = "auth0-tfstate-access"
  role   = aws_iam_role.github.id
  policy = data.aws_iam_policy_document.state_access.json
}
