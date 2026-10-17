terraform {
  required_version = ">= 1.10.0"

  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 1.0"
    }
  }

  # Remote state. Bucket/region/lock table come from backend.hcl
  # (terraform init -backend-config=backend.hcl) so this file stays identical across envs.
  backend "s3" {}
}

# Credentials come from environment variables so nothing secret lives in git:
#   AUTH0_DOMAIN, AUTH0_CLIENT_ID, AUTH0_CLIENT_SECRET
# These belong to a Machine-to-Machine app in THIS tenant, authorised for the
# Auth0 Management API (see README for the required scopes).
provider "auth0" {
  debug = false
}

locals {
  config = yamldecode(file("${path.module}/apps.yaml"))
  apps   = { for app in try(local.config.applications, []) : app.name => app }
}

module "client" {
  source   = "../../modules/auth0-client"
  for_each = local.apps

  name                = "${each.value.name}${var.name_suffix}"
  description         = try(each.value.description, "")
  app_type            = each.value.app_type
  callbacks           = try(each.value.callbacks, [])
  allowed_logout_urls = try(each.value.logout_urls, [])
  web_origins         = try(each.value.web_origins, [])
  allowed_origins     = try(each.value.allowed_origins, [])
  grant_types         = try(each.value.grant_types, [])
  api_grants          = try(each.value.api_grants, [])
  metadata = merge(
    { environment = var.environment, managed_by = "terraform" },
    { for k, v in try(each.value.metadata, {}) : k => tostring(v) }
  )
}
