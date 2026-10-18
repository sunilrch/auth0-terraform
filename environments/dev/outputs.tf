output "client_ids" {
  value = module.tenant.client_ids
}

output "client_secrets" {
  value     = module.tenant.client_secrets
  sensitive = true
}

output "api_identifiers" {
  value = module.tenant.api_identifiers
}

output "connections" {
  value = module.tenant.connections
}

output "roles" {
  value = module.tenant.roles
}
