# ---------------------------------------------------------------------------
# GitHub: environments, approvals, secrets and branch protection
# ---------------------------------------------------------------------------
data "github_user" "reviewer" {
  for_each = toset(flatten([for e in var.environments : e.required_reviewers]))
  username = each.value
}

# Apply environments (dev, qa, ...): hold secrets, may require approval, main branch only.
resource "github_repository_environment" "apply" {
  for_each = var.environments

  repository          = local.repo
  environment         = each.key
  prevent_self_review = false

  dynamic "reviewers" {
    for_each = length(each.value.required_reviewers) > 0 ? [1] : []
    content {
      users = [for u in each.value.required_reviewers : data.github_user.reviewer[u].id]
    }
  }

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "main_only" {
  for_each = var.environments

  repository     = local.repo
  environment    = github_repository_environment.apply[each.key].environment
  branch_pattern = "main"
}

# Plan environments (dev-plan, ...): same secrets, no approval, used by PRs and manual runs.
resource "github_repository_environment" "plan" {
  for_each = var.environments

  repository  = local.repo
  environment = "${each.key}-plan"
}

locals {
  github_env_names = merge(
    { for k, v in var.environments : k => k },
    { for k, v in var.environments : "${k}-plan" => k },
  )

  github_secrets = merge([
    for gh_env, tenant in local.github_env_names : {
      "${gh_env}/AUTH0_DOMAIN"        = { env = gh_env, name = "AUTH0_DOMAIN", value = var.environments[tenant].auth0_domain }
      "${gh_env}/AUTH0_CLIENT_ID"     = { env = gh_env, name = "AUTH0_CLIENT_ID", value = var.environments[tenant].auth0_client_id }
      "${gh_env}/AUTH0_CLIENT_SECRET" = { env = gh_env, name = "AUTH0_CLIENT_SECRET", value = var.auth0_client_secrets[tenant] }
      "${gh_env}/AWS_STATE_ROLE_ARN"  = { env = gh_env, name = "AWS_STATE_ROLE_ARN", value = aws_iam_role.github.arn }
    }
  ]...)
}

resource "github_actions_environment_secret" "this" {
  for_each = nonsensitive(toset(keys(local.github_secrets)))

  repository      = local.repo
  environment     = local.github_secrets[each.key].env
  secret_name     = local.github_secrets[each.key].name
  plaintext_value = local.github_secrets[each.key].value

  depends_on = [github_repository_environment.apply, github_repository_environment.plan]
}

# main: changes only via pull request, no force-push, no deletion.
resource "github_repository_ruleset" "main" {
  name        = "protect-main"
  repository  = local.repo
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    pull_request {
      required_approving_review_count = var.required_pr_approvals
    }
  }
}
