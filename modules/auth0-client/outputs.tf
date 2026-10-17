output "client_id" {
  description = "Auth0 client ID of the registered application."
  value       = auth0_client.this.client_id
}

output "name" {
  value = auth0_client.this.name
}

output "app_type" {
  value = auth0_client.this.app_type
}

output "client_secret" {
  description = "Client secret (null for public clients). Read with: terraform output -json client_secrets"
  value       = local.is_public_client ? null : auth0_client_credentials.this.client_secret
  sensitive   = true
}
