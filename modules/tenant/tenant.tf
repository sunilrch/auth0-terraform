# ---------------------------------------------------------------------------
# Tenant-wide settings (tenant.yaml -> settings / security / mfa)
# Note: a tenant can't be created by Terraform; this configures an existing one.
# ---------------------------------------------------------------------------
resource "auth0_tenant" "this" {
  friendly_name         = try(local.settings.friendly_name, null)
  support_email         = try(local.settings.support_email, null)
  support_url           = try(local.settings.support_url, null)
  picture_url           = try(local.settings.logo_url, null)
  session_lifetime      = try(local.settings.session_lifetime_hours, 72)
  idle_session_lifetime = try(local.settings.idle_session_lifetime_hours, 24)
  enabled_locales       = try(local.settings.enabled_locales, ["en"])
  allowed_logout_urls   = try(local.settings.allowed_logout_urls, [])
}

resource "auth0_attack_protection" "this" {
  brute_force_protection {
    enabled      = try(local.security.brute_force_protection, true)
    mode         = "count_per_identifier_and_ip"
    max_attempts = try(local.security.brute_force_max_attempts, 10)
    shields      = ["block", "user_notification"]
  }

  suspicious_ip_throttling {
    enabled = try(local.security.suspicious_ip_throttling, true)
    shields = ["block", "admin_notification"]
  }

  # Breached password detection needs a paid Auth0 plan.
  breached_password_detection {
    enabled = try(local.security.breached_password_detection, false)
    method  = "standard"
    shields = ["block"]
  }
}

resource "auth0_guardian" "this" {
  # "never" = MFA off, "all-applications" = always ask, "confidence-score" = adaptive (paid)
  policy        = try(local.mfa.policy, "never")
  otp           = try(local.mfa.otp, true)
  recovery_code = try(local.mfa.recovery_code, true)
  email         = try(local.mfa.email, false)
}
