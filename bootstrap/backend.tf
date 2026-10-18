# Step 2 of bootstrapping: rename this file to backend.tf, then run
#   terraform init -migrate-state
# to move the bootstrap state into the bucket it just created.
terraform {
  backend "s3" {
    bucket       = "auth0-tfstate-117227383260"
    key          = "bootstrap/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
