provider "aws" {
  version = "~> 1.5"
  region = "${var.region}"
}

terraform {
  backend "s3" { }
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.identifier}-${var.environment}-${var.name}"
  region = "${var.region}"
  acl = "${var.public ? "public" : "private"}"

  tags {
    Name = "${var.identifier}-${var.environment}-${var.name}"
  }
}
