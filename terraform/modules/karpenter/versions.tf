terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      # >= 6.0 for data.aws_region's `region` attribute (`name` is deprecated).
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}
