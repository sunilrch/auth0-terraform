locals {
  default_grant_types = {
    spa             = ["authorization_code", "refresh_token", "implicit"]
    regular_web     = ["authorization_code", "refresh_token", "implicit"]
    native          = ["authorization_code", "refresh_token", "implicit"]
    non_interactive = ["client_credentials"]
  }

  grant_types = length(var.grant_types) > 0 ? var.grant_types : local.default_grant_types[var.app_type]

  # Public clients (browser / mobile) cannot keep a secret.
  is_public_client      = contains(["spa", "native"], var.app_type)
  authentication_method = local.is_public_client ? "none" : "client_secret_post"
}

resource "auth0_client" "this" {
  name                = var.name
  description         = var.description
  app_type            = var.app_type
  callbacks           = var.callbacks
  allowed_logout_urls = var.allowed_logout_urls
  web_origins         = var.web_origins
  allowed_origins     = var.allowed_origins
  grant_types         = local.grant_types
  oidc_conformant     = true
  is_first_party      = true
  client_metadata     = var.metadata

  jwt_configuration {
    alg                 = "RS256"
    lifetime_in_seconds = var.token_lifetime
  }

  dynamic "refresh_token" {
    for_each = contains(local.grant_types, "refresh_token") ? [1] : []
    content {
      rotation_type                = "rotating"
      expiration_type              = "expiring"
      leeway                       = 0
      token_lifetime               = 2592000 # 30 days absolute
      idle_token_lifetime          = 1296000 # 15 days idle
      infinite_token_lifetime      = false
      infinite_idle_token_lifetime = false
    }
  }
}

resource "auth0_client_credentials" "this" {
  client_id             = auth0_client.this.id
  authentication_method = local.authentication_method
}

resource "auth0_client_grant" "this" {
  for_each = { for g in var.api_grants : g.audience => g }

  client_id = auth0_client.this.id
  audience  = each.value.audience
  scopes    = each.value.scopes
}
