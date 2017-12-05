provider "aws" {
  version = "~> 1.5"
  region = "${var.region}"
}

terraform {
  backend "s3" { }
}
