terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.74.2"
    }
  }
backend "remote" {
  hostname = "app.terraform.io"
  organization = "vivek-personal"

  workspaces {
    name = "spotifyVisualisation"
  }
  
}
  required_version = ">= 0.14.9"
}


provider "aws" {
  region = var.region
  profile = "vivek-personal-iam-user"
}
