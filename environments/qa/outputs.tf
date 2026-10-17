output "client_ids" {
  description = "Map of application name => Auth0 client ID."
  value       = { for k, m in module.client : k => m.client_id }
}

output "client_secrets" {
  description = "Map of application name => client secret (confidential apps only)."
  value       = { for k, m in module.client : k => m.client_secret if m.client_secret != null }
  sensitive   = true
}
