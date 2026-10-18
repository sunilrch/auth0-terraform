output "client_ids" {
  description = "Application name => Auth0 client ID."
  value       = { for k, m in module.client : k => m.client_id }
}

output "client_secrets" {
  description = "Application name => client secret (confidential apps only)."
  value       = { for k, m in module.client : k => m.client_secret if m.client_secret != null }
  sensitive   = true
}

output "api_identifiers" {
  description = "APIs registered in this tenant."
  value       = [for k, a in auth0_resource_server.api : a.identifier]
}

output "connections" {
  description = "Connection name => ID."
  value       = { for k, c in auth0_connection.this : k => c.id }
}

output "roles" {
  description = "Role name => ID."
  value       = { for k, r in auth0_role.this : k => r.id }
}
