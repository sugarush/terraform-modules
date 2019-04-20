provider "aws" {
  version = "~> 1.5"
  region = "${var.region}"
}

terraform {
  backend "s3" { }
}

data "aws_vpc" "local" {
  tags {
    Name = "${var.identifier}-${var.environment}"
  }
}

data "aws_vpc" "remote" {
  tags {
    Name = "${var.remote}"
  }
}

data "aws_route_tables" "local" {

  filter {
    name = "tag:Name"
    values = [ "*" ]
  }

  vpc_id = "${data.aws_vpc.local.id}"
}

data "aws_route_tables" "remote" {

  filter {
    name = "tag:Name"
    values = [ "*" ]
  }

  vpc_id = "${data.aws_vpc.remote.id}"
}

resource "aws_vpc_peering_connection" "this" {
  vpc_id = "${data.aws_vpc.local.id}"
  peer_vpc_id = "${data.aws_vpc.remote.id}"
  auto_accept = true

  tags {
    Name = "${var.identifier}-${var.environment} to ${var.remote}"
  }
}

resource "aws_route" "local" {
  vpc_peering_connection_id = "${aws_vpc_peering_connection.this.id}"
  route_table_id = "${data.aws_route_tables.local.ids[count.index]}"
  destination_cidr_block = "${data.aws_vpc.remote.cidr_block}"
  count = "${length(data.aws_route_tables.local.ids)}"
}

resource "aws_route" "remote" {
  vpc_peering_connection_id = "${aws_vpc_peering_connection.this.id}"
  route_table_id = "${data.aws_route_tables.remote.ids[count.index]}"
  destination_cidr_block = "${data.aws_vpc.local.cidr_block}"
  count = "${length(data.aws_route_tables.remote.ids)}"
}
