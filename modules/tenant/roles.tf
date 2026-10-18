# ---------------------------------------------------------------------------
# Roles and the API permissions they grant (roles.yaml)
# ---------------------------------------------------------------------------
resource "auth0_role" "this" {
  for_each = local.roles

  name        = each.value.name
  description = try(each.value.description, each.value.name)
}

resource "auth0_role_permissions" "this" {
  for_each = { for k, v in local.roles : k => v if length(try(v.permissions, [])) > 0 }

  role_id = auth0_role.this[each.key].id

  dynamic "permissions" {
    for_each = flatten([
      for p in each.value.permissions : [
        for s in p.scopes : { api = p.api, scope = s }
      ]
    ])
    content {
      resource_server_identifier = permissions.value.api
      name                       = permissions.value.scope
    }
  }

  depends_on = [auth0_resource_server_scopes.api]
}
