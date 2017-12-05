provider "aws" {
  version = "~> 1.5"
  region = "${var.region}"
}

terraform {
  backend "s3" { }
}

data "aws_vpc" "selected" {
  tags {
    Name = "${var.identifier}-${var.environment}"
  }
}

resource "aws_security_group" "this" {
  vpc_id = "${data.aws_vpc.selected.id}"

  tags {
    Name = "${var.identifier}-${var.environment}-${var.role}"
  }
}
