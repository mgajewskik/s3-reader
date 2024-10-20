terraform {
  required_version = "~> 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.72.1"
    }
  }

  # NOTE: change this if deploying to your own AWS account
  backend "s3" {
    bucket = "terraform-state-220263133738"
    key    = "s3-reader/terraform.tfstate"
    region = "eu-west-1"
  }
}
