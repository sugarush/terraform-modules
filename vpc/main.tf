provider "aws" {
  version = "~> 1.5"
  region = "${var.region}"
}

terraform {
  backend "s3" { }
}

resource "aws_vpc" "this" {
  cidr_block = "${var.cidr}"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags {
    Name = "${var.identifier}-${var.environment}"
  }
}

resource "aws_vpc_dhcp_options" "this" {
  domain_name = "${var.identifier}-${var.environment}.${var.region}.aws."
  domain_name_servers = "${var.domain_name_servers}"

  tags {
    Name = "${var.identifier}-${var.environment}"
  }
}

resource "aws_vpc_dhcp_options_association" "this" {
  vpc_id = "${aws_vpc.this.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.this.id}"
}

resource "aws_subnet" "public" {
    count = "${length(var.public_subnets)}"

    vpc_id = "${aws_vpc.this.id}"
    cidr_block = "${var.public_subnets[count.index]}"
    availability_zone = "${var.region}${element(var.availability_zones, count.index)}"

    tags {
      Name = "${var.identifier}-${var.environment}-public"
      Tier = "public"
    }
}

resource "aws_subnet" "private" {
    count = "${length(var.private_subnets)}"

    vpc_id = "${aws_vpc.this.id}"
    cidr_block = "${var.private_subnets[count.index]}"
    availability_zone = "${var.region}${element(var.availability_zones, count.index)}"

    tags {
      Name = "${var.identifier}-${var.environment}-private"
      Tier = "private"
    }
}

resource "aws_internet_gateway" "this" {
  vpc_id = "${aws_vpc.this.id}"

  tags {
    Name = "${var.identifier}-${var.environment}"
  }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "this" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.public.0.id}"

  depends_on = [ "aws_internet_gateway.this" ]
}

resource "aws_route_table" "public" {
  depends_on = [ "aws_internet_gateway.this" ]

  vpc_id = "${aws_vpc.this.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.this.id}"
  }

  tags {
    Name = "${var.identifier}-${var.environment}-public"
  }
}

resource "aws_route_table" "private" {
  depends_on = [ "aws_nat_gateway.this" ]

  vpc_id = "${aws_vpc.this.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.this.id}"
  }

  tags {
    Name = "${var.identifier}-${var.environment}-private"
  }
}

resource "aws_route_table_association" "public" {
  depends_on = [ "aws_route_table.public" ]

  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
  count = "${length(var.public_subnets)}"
}

resource "aws_route_table_association" "private" {
  depends_on = [ "aws_route_table.private" ]

  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
  count = "${length(var.private_subnets)}"
}

resource "aws_route53_zone" "private" {
  name = "${var.identifier}-${var.environment}.${var.region}.aws."

  vpc_id = "${aws_vpc.this.id}"

  tags {
    Name = "${var.identifier}-${var.environment}"
  }
}

resource "aws_route53_record" "private" {
  zone_id = "${aws_route53_zone.private.id}"

  name = "${var.identifier}-${var.environment}.${var.region}.aws."
  type = "NS"
  ttl = "30"

  records = [
    "${aws_route53_zone.private.name_servers.0}",
    "${aws_route53_zone.private.name_servers.1}",
    "${aws_route53_zone.private.name_servers.2}",
    "${aws_route53_zone.private.name_servers.3}"
  ]
}
