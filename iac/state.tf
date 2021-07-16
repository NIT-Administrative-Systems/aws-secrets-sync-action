terraform {
  backend "s3" {
    bucket = "ado-nonprod-build-tfstate"
    key    = "ssm-secrets-sync-action/tech-demo/terraform.tfstate"
    region = "us-east-2"
  }
}
