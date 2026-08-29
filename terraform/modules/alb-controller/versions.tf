terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      # >= 6.0 to match the rest of the modules (data.aws_region `region`).
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}
