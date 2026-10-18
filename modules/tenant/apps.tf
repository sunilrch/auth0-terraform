# ---------------------------------------------------------------------------
# Applications (apps.yaml). Created after APIs so api_grants never point at
# an API that doesn't exist yet.
# ---------------------------------------------------------------------------
module "client" {
  source   = "../auth0-client"
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

  depends_on = [auth0_resource_server_scopes.api]
}
