variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "state_bucket_name" {
  description = "S3 bucket holding Terraform state for all Auth0 tenants."
  type        = string
  default     = "auth0-tfstate-117227383260"
}

variable "github_role_name" {
  type    = string
  default = "github-auth0-terraform"
}

variable "github_repo" {
  description = "owner/repo allowed to assume the role."
  type        = string
  default     = "sunilrch/auth0-terraform"
}

variable "github_repo_ids" {
  description = "GitHub's immutable owner and repo IDs, as they appear in the OIDC 'sub' claim (owner@ID/repo@ID)."
  type = object({
    owner_id = string
    repo_id  = string
  })
  default = {
    owner_id = "56264447"
    repo_id  = "1423237188"
  }
}
