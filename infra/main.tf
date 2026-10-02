# Root Terraform entrypoint for the Vivavere AWS account.
#
# Scope today is deliberately small: the vivavere.com registration settings
# (domain.tf), its mail DNS for Migadu mailboxes such as contact@ (email.tf),
# and an account-wide cost budget (budgets.tf). Nothing is hosted yet.
#
# State lives in the S3 bucket the estate account bootstrap created in this
# account (`vivavere-tfstate-<account-id>`). Locking is S3-native via
# `use_lockfile`, so there is no DynamoDB table.
#
# `bucket` is the one partial-config value: its name embeds the AWS account ID,
# which stays out of this public repo. Pass it with
# `terraform init -backend-config=backend.config` (gitignored; shape in
# backend.config.example).

terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.44"
    }
  }

  backend "s3" {
    key          = "envs/prod/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      project     = var.project
      managed_by  = "terraform"
      environment = var.environment
    }
  }
}

# Route 53 Domains is served only from us-east-1, so the registration settings
# are pinned there regardless of var.aws_region.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      project     = var.project
      managed_by  = "terraform"
      environment = var.environment
    }
  }
}
