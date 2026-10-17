# auth0-terraform

Registers client applications in our four Auth0 tenants — **dev, qa, staging, prod** — using Terraform. Each tenant has its own folder, its own state, and its own credentials. App teams register an application by editing a YAML file and opening a PR.

```
auth0-terraform/
├── modules/auth0-client/        # reusable module: one Auth0 application
│   ├── main.tf                  # auth0_client, auth0_client_credentials, auth0_client_grant
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── environments/
│   ├── dev/                     # one folder per tenant
│   │   ├── apps.yaml            # <-- the applications registered in this tenant
│   │   ├── main.tf              # reads apps.yaml, calls the module per app
│   │   ├── variables.tf / outputs.tf
│   │   ├── terraform.tfvars     # environment name, app-name suffix
│   │   └── backend.hcl          # remote state location for this tenant
│   ├── qa/
│   ├── staging/
│   └── prod/
└── .github/workflows/terraform.yml   # plan on PR, apply on merge
```

## Registering an application

1. Edit `environments/<env>/apps.yaml` and add an entry:

   ```yaml
   - name: billing-web
     description: Billing admin UI
     app_type: regular_web          # spa | regular_web | native | non_interactive
     callbacks:    [https://billing.dev.example.com/callback]
     logout_urls:  [https://billing.dev.example.com]
     web_origins:  [https://billing.dev.example.com]
     metadata:
       owner_team: billing
   ```

   For a machine-to-machine app use `app_type: non_interactive` and list the APIs it calls:

   ```yaml
     api_grants:
       - audience: https://orders-api.dev.example.com
         scopes: [read:orders]
   ```

   The API (resource server) must already exist in that tenant.

2. Open a PR. The pipeline posts a `terraform plan` for every tenant as a PR comment.
3. Merge to `main`. The pipeline applies dev → qa → staging → prod in order, pausing for approval where the GitHub Environment requires it.
4. Get the client ID (and secret for confidential apps):

   ```bash
   terraform output client_ids
   terraform output -json client_secrets   # sensitive
   ```

Promote an app by copying its entry into the next tenant's `apps.yaml` with that tenant's URLs.

## Tenants

| Environment | Tenant | AUTH0_DOMAIN |
|---|---|---|
| dev     | `dev-kzcv7r6k5z6za53d` (US) | `dev-kzcv7r6k5z6za53d.us.auth0.com` |
| qa      | _not created yet_ | |
| staging | _not created yet_ | |
| prod    | _not created yet_ | |

## One-time setup

### 1. Terraform M2M app in each tenant
Terraform needs its own credentials in **each** of the 4 tenants. In every tenant:

1. Applications → Create Application → *Machine to Machine*, name it `terraform-provisioner`.
2. Authorise it for the **Auth0 Management API** with at least these scopes:
   `read:clients`, `create:clients`, `update:clients`, `delete:clients`,
   `read:client_keys`, `update:client_keys`,
   `read:client_grants`, `create:client_grants`, `update:client_grants`, `delete:client_grants`,
   `read:resource_servers`.
3. Note its domain, client ID and client secret.

This bootstrap app is created by hand once; everything else is managed by Terraform.

### 2. Remote state
Create an S3 bucket and a DynamoDB lock table (or switch `backend "s3"` in `main.tf` to your organisation's backend), then update the `bucket` and `dynamodb_table` values in each `environments/*/backend.hcl`. Each tenant uses a separate state key.

### 3. GitHub Environments and secrets
In the repo → Settings → Environments, create:

| Environment     | Used for                  | Protection                    |
|-----------------|---------------------------|-------------------------------|
| `dev-plan`, `qa-plan`, `staging-plan`, `prod-plan` | PR plans | none |
| `dev`, `qa`     | apply on merge            | none (or optional)            |
| `staging`, `prod` | apply on merge          | required reviewers            |

Add these secrets to **each** environment (the plan and apply environment of the same tenant use the same values):

- `AUTH0_DOMAIN` — e.g. `mycompany-dev.eu.auth0.com`
- `AUTH0_CLIENT_ID` / `AUTH0_CLIENT_SECRET` — from the `terraform-provisioner` app in that tenant
- `AWS_STATE_ROLE_ARN` — IAM role the workflow assumes (via OIDC) to read/write state

Also enable branch protection on `main` so changes only land through reviewed PRs.

## Running locally

```bash
cd environments/dev
export AUTH0_DOMAIN=mycompany-dev.eu.auth0.com
export AUTH0_CLIENT_ID=...
export AUTH0_CLIENT_SECRET=...
terraform init -backend-config=backend.hcl
terraform plan
```

## Importing applications that already exist

```bash
terraform import 'module.client["existing-app"].auth0_client.this' <client_id>
terraform import 'module.client["existing-app"].auth0_client_credentials.this' <client_id>
```

Add a matching entry to `apps.yaml` first, then run `terraform plan` and adjust until there's no diff.

## Notes

- Client secrets end up in Terraform state, so the state bucket must be encrypted and access-restricted.
- `spa` and `native` apps are public clients (no secret); `regular_web` and `non_interactive` get a secret.
- Refresh token rotation is on by default for apps that use the `refresh_token` grant.
