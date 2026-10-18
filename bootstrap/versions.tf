terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  # No backend here on purpose: the first apply uses local state because the
  # bucket doesn't exist yet. Afterwards, rename backend.tf.example -> backend.tf
  # and run `terraform init -migrate-state` to move this state into the bucket.
}

provider "aws" {
  region = var.aws_region
}

# Token comes from the GITHUB_TOKEN environment variable (fine-grained PAT with
# Administration, Environments, Secrets: read & write on this repo).
provider "github" {
  owner = local.owner
}
