terraform {
  required_version = ">= 1.10.0"

  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 1.0"
    }
  }

  # Bucket / key / region / locking come from backend.hcl:
  #   terraform init -backend-config=backend.hcl
  backend "s3" {}
}

# Credentials come from environment variables (never from git):
#   AUTH0_DOMAIN, AUTH0_CLIENT_ID, AUTH0_CLIENT_SECRET
# = the "terraform-provisioner" Machine-to-Machine app of THIS environment's tenant.
provider "auth0" {}

# Everything in this tenant is defined by the YAML files in this folder:
#   tenant.yaml       tenant settings, security, MFA, login Actions
#   connections.yaml  login methods (database, Google, ...)
#   apis.yaml         APIs and their scopes
#   roles.yaml        roles and the API permissions they grant
#   apps.yaml         applications
module "tenant" {
  source = "../../modules/tenant"

  config_dir  = path.module
  environment = var.environment
  name_suffix = var.name_suffix
}
