# ---------------------------------------------------------------------------
# Login methods (connections.yaml) and which apps may use them
# ---------------------------------------------------------------------------
resource "auth0_connection" "this" {
  for_each = local.connections

  name     = each.value.name
  strategy = each.value.strategy # "auth0" (email/password database) or "google-oauth2"

  options {
    # Database connections
    password_policy        = each.value.strategy == "auth0" ? try(each.value.password_policy, "good") : null
    brute_force_protection = each.value.strategy == "auth0" ? true : null
    disable_signup         = each.value.strategy == "auth0" ? try(each.value.disable_signup, false) : null
    requires_username      = each.value.strategy == "auth0" ? try(each.value.requires_username, false) : null

    # Google: leave client_id empty to use Auth0's dev keys (fine for dev, not for prod)
    client_id = each.value.strategy == "google-oauth2" ? try(each.value.client_id, null) : null
    scopes    = each.value.strategy == "google-oauth2" ? ["email", "profile"] : null
  }
}

locals {
  all_client_ids = [for k, m in module.client : m.client_id]

  connection_client_ids = {
    for name, c in local.connections : name => (
      try(c.enabled_for_apps, "all") == "all"
      ? local.all_client_ids
      : [for app in c.enabled_for_apps : module.client[app].client_id]
    )
  }
}

resource "auth0_connection_clients" "this" {
  for_each = local.connections

  connection_id   = auth0_connection.this[each.key].id
  enabled_clients = local.connection_client_ids[each.key]
}
