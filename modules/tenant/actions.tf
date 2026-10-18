# ---------------------------------------------------------------------------
# Login Actions (tenant.yaml -> actions)
# add_roles_to_tokens: puts the user's roles into ID and access tokens as
#   "<namespace>/roles" so apps and APIs can check them.
# ---------------------------------------------------------------------------
locals {
  add_roles     = try(local.actions.add_roles_to_tokens, false)
  roles_ns      = try(local.actions.claims_namespace, "https://example.com")
  action_suffix = var.name_suffix == "" ? "" : "-${var.environment}"
}

resource "auth0_action" "add_roles" {
  count = local.add_roles ? 1 : 0

  name    = "add-roles-to-tokens${local.action_suffix}"
  runtime = try(local.actions.runtime, "node22")
  deploy  = true
  code    = <<-EOT
    exports.onExecutePostLogin = async (event, api) => {
      const claim = '${local.roles_ns}/roles';
      const roles = (event.authorization && event.authorization.roles) || [];
      api.idToken.setCustomClaim(claim, roles);
      api.accessToken.setCustomClaim(claim, roles);
    };
  EOT

  supported_triggers {
    id      = "post-login"
    version = "v3"
  }
}

resource "auth0_trigger_actions" "post_login" {
  count   = local.add_roles ? 1 : 0
  trigger = "post-login"

  actions {
    id           = auth0_action.add_roles[0].id
    display_name = auth0_action.add_roles[0].name
  }
}
