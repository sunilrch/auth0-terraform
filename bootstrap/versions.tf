terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Bootstrap state lives in the same bucket it manages, under its own key.
  # The GitHub Actions role can only touch auth0/*, so it cannot read or change this.
  backend "s3" {
    bucket       = "auth0-tfstate-117227383260"
    key          = "bootstrap/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}
