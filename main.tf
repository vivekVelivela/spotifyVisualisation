terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.75.2"
    }
  }
backend "remote" {
  hostname = "app.terraform.io"
  organization = "vivek-personal"

  workspaces {
    name = "spotifyVisualisation_dev"
  }
  
}
  required_version = ">= 0.14.9"
}


provider "aws" {
  region = var.region
  profile = "vivek-personal-iam-user"
  access_key =  var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}
