terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # No remote backend configured yet — state is local. Fine for a single-
  # operator portfolio project; CI validates with `init -backend=false`.
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "eks-gitops-observability"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}
