# Remote state for the dev tenant. Replace the bucket name with yours.
bucket       = "auth0-tfstate-117227383260"
key          = "auth0/dev/terraform.tfstate"
region       = "ap-south-1"
encrypt      = true
use_lockfile = true   # S3-native state locking (Terraform >= 1.10), no DynamoDB needed
