terraform {
  backend "remote" {}
}

provider "aws" {
  region = "ap-southeast-2"
}
