# ---------------------------------------------------------------------------
# Read the YAML files for this environment. Every file is optional; a missing
# or empty file simply means "nothing of that kind".
# ---------------------------------------------------------------------------
locals {
  tenant_cfg = try(yamldecode(file("${var.config_dir}/tenant.yaml")), {})

  connections = try({ for c in yamldecode(file("${var.config_dir}/connections.yaml")).connections : c.name => c }, {})
  apis        = try({ for a in yamldecode(file("${var.config_dir}/apis.yaml")).apis : a.identifier => a }, {})
  roles       = try({ for r in yamldecode(file("${var.config_dir}/roles.yaml")).roles : r.name => r }, {})
  apps        = try({ for a in yamldecode(file("${var.config_dir}/apps.yaml")).applications : a.name => a }, {})

  settings = try(local.tenant_cfg.settings, {})
  security = try(local.tenant_cfg.security, {})
  mfa      = try(local.tenant_cfg.mfa, {})
  actions  = try(local.tenant_cfg.actions, {})
}
