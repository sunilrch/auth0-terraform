# ---------------------------------------------------------------------------
# APIs (resource servers) and their scopes (apis.yaml)
# ---------------------------------------------------------------------------
resource "auth0_resource_server" "api" {
  for_each = local.apis

  name                                            = each.value.name
  identifier                                      = each.value.identifier
  signing_alg                                     = "RS256"
  token_lifetime                                  = try(each.value.token_lifetime_seconds, 86400)
  allow_offline_access                            = try(each.value.allow_offline_access, false)
  skip_consent_for_verifiable_first_party_clients = true

  # rbac: true -> Auth0 enforces role/permission checks and adds "permissions" to access tokens
  enforce_policies = try(each.value.rbac, false)
  token_dialect    = try(each.value.rbac, false) ? "access_token_authz" : "access_token"
}

resource "auth0_resource_server_scopes" "api" {
  for_each = { for k, v in local.apis : k => v if length(try(v.scopes, [])) > 0 }

  resource_server_identifier = auth0_resource_server.api[each.key].identifier

  dynamic "scopes" {
    for_each = each.value.scopes
    content {
      name        = scopes.value.name
      description = try(scopes.value.description, null)
    }
  }
}
