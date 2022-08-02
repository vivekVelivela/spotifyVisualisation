terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
    backend "remote" {}
  }

  required_version = ">= 0.14.9"
}


provider "aws" {
  region = "ap-southeast-2"
  profile = "vivek-personal-iam-user"
}
