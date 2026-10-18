# auth0-terraform

Everything about our Auth0 tenants (dev, qa, staging, prod) is defined in this repo and applied by Terraform:
tenant settings, security, MFA, login methods, APIs, roles, login Actions and applications.
The AWS state storage and the GitHub environments/secrets/branch rules are Terraform too (`bootstrap/`).

The only things done by hand are the ones no API exists for: **creating a tenant** and the
**first `terraform-provisioner` app** in it (Terraform needs it to log in).

## Layout

```
bootstrap/                      # run by an admin from a laptop - never by the pipeline
  main.tf                       # S3 state bucket, GitHub OIDC provider, IAM role for Actions
  github.tf                     # GitHub environments, approvals, secrets, main-branch ruleset
  variables.tf                  # which environments exist, their Auth0 domain/client id, reviewers
  secrets.auto.tfvars.example   # copy to secrets.auto.tfvars (git-ignored) for provisioner secrets
  backend.tf.example            # rename to backend.tf after the first apply (moves state to S3)

modules/
  tenant/                       # everything inside one tenant, driven by the YAML files below
  auth0-client/                 # one application

environments/<env>/             # one folder per tenant, applied by the pipeline
  tenant.yaml                   # settings, session lifetimes, brute-force/bot protection, MFA, Actions
  connections.yaml              # login methods (email/password database, Google) + which apps use them
  apis.yaml                     # APIs (resource servers) and their scopes
  roles.yaml                    # roles and the API permissions they grant
  apps.yaml                     # applications (SPA, web, native, machine-to-machine)
  main.tf / backend.hcl         # wiring + state location

.github/workflows/terraform.yml # plan on PR, apply on merge (dev -> qa -> staging -> prod)
```

## Day-to-day: changing anything in a tenant

1. `git checkout -b my-change`
2. Edit the YAML for that environment (e.g. add an app to `environments/dev/apps.yaml`).
3. `terraform fmt -recursive`, commit, push, open a PR - the plan for each tenant is posted on the PR.
4. Merge. dev applies automatically; qa / staging / prod wait for approval in the Actions run.

Never change these things in the Auth0 dashboard: the next run puts them back to what git says.

## Building everything from scratch

### 0. Manual, once per tenant (no API exists for these)
1. **Create the tenant** in the Auth0 dashboard (tenant dropdown -> Create tenant).
2. **Create `terraform-provisioner`**: Applications -> Create Application -> Machine to Machine ->
   Auth0 Management API -> **Client Access**, select:

   | Area | Permissions |
   |---|---|
   | Applications | `read:clients` `create:clients` `update:clients` `delete:clients` |
   | App keys / credentials | `read:client_keys` `update:client_keys` `read:client_credentials` `create:client_credentials` `update:client_credentials` `delete:client_credentials` |
   | App -> API grants | `read:client_grants` `create:client_grants` `update:client_grants` `delete:client_grants` |
   | APIs | `read:resource_servers` `create:resource_servers` `update:resource_servers` `delete:resource_servers` |
   | Login methods | `read:connections` `create:connections` `update:connections` `delete:connections` |
   | Roles | `read:roles` `create:roles` `update:roles` `delete:roles` |
   | Tenant settings | `read:tenant_settings` `update:tenant_settings` |
   | Attack protection | `read:attack_protection` `update:attack_protection` |
   | MFA | `read:guardian_factors` `update:guardian_factors` `read:mfa_policies` `update:mfa_policies` |
   | Actions | `read:actions` `create:actions` `update:actions` `delete:actions` |

   Note its domain, client ID and client secret.

### 1. Bootstrap AWS + GitHub (from your laptop)
Needs: AWS admin credentials, Terraform >= 1.10, and a GitHub fine-grained token with
**Administration, Environments, Secrets: read & write** on this repo.

```powershell
cd bootstrap
Copy-Item secrets.auto.tfvars.example secrets.auto.tfvars   # fill in the provisioner secret(s)
$env:GITHUB_TOKEN = "<fine-grained token>"
# check variables.tf -> environments (domain + client id per environment)

terraform init
terraform apply          # S3 bucket, OIDC provider, IAM role, GitHub environments + secrets + ruleset

Rename-Item backend.tf.example backend.tf
terraform init -migrate-state                              # move bootstrap state into the bucket
Remove-Item terraform.tfstate, terraform.tfstate.backup -ErrorAction SilentlyContinue
```

If you created a `main` ruleset by hand before, delete it first (Settings -> Rules), or you'll have two.

### 2. Everything inside the tenant
Open a PR that touches `environments/` (or Actions -> Run workflow to just see the plans), merge it,
approve. The pipeline creates tenant settings, security, MFA, connections, APIs, roles, Actions and apps.

### Adding qa / staging / prod
Each needs its **own** tenant (tenant settings, connections and Actions can't be shared between environments).
1. Do step 0 in the new tenant.
2. Add it to `environments` in `bootstrap/variables.tf` and its secret to `secrets.auto.tfvars`; `terraform apply` in `bootstrap/`.
3. Add it to `matrix.env` in `.github/workflows/terraform.yml`, PR, merge, approve.

## Running locally

```powershell
cd environments\dev
$env:AUTH0_DOMAIN        = "dev-kzcv7r6k5z6za53d.us.auth0.com"
$env:AUTH0_CLIENT_ID     = '...'
$env:AUTH0_CLIENT_SECRET = '...'
terraform init -backend-config="backend.hcl"
terraform plan
```

## Notes
- Client secrets end up in Terraform state; the state bucket is encrypted, versioned and private,
  and the pipeline's role can only reach `auth0/*` in it.
- `spa` and `native` apps have no secret; `regular_web` and `non_interactive` do.
- Breached-password detection and adaptive MFA need a paid Auth0 plan (`tenant.yaml`).
- Google login without `client_id` uses Auth0's dev keys - fine for dev, set real keys for prod.
