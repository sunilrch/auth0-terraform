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

# ---------------------------------------------------------------------------
# GitHub / Auth0 wiring
# ---------------------------------------------------------------------------
variable "environments" {
  description = <<-EOT
    One entry per environment that has its own Auth0 tenant.
    auth0_domain / auth0_client_id = that tenant's terraform-provisioner app.
    required_reviewers = GitHub usernames who must approve applies (empty = no approval).
  EOT
  type = map(object({
    auth0_domain       = string
    auth0_client_id    = string
    required_reviewers = list(string)
  }))
  default = {
    dev = {
      auth0_domain       = "dev-kzcv7r6k5z6za53d.us.auth0.com"
      auth0_client_id    = "Sek95BKv76jF3yX7OvMbba1h5Lyoj0rQ"
      required_reviewers = []
    }
    # Add qa / staging / prod here once each has its own Auth0 tenant, e.g.:
    # prod = {
    #   auth0_domain       = "yourco-prod.us.auth0.com"
    #   auth0_client_id    = "..."
    #   required_reviewers = ["sunilrch"]
    # }
  }
}

variable "auth0_client_secrets" {
  description = "Environment name => terraform-provisioner client secret. Put in secrets.auto.tfvars (git-ignored), never in git."
  type        = map(string)
  sensitive   = true
}

variable "required_pr_approvals" {
  description = "Approving reviews needed before merging to main. Keep 0 while you are the only person on the repo."
  type        = number
  default     = 0
}
