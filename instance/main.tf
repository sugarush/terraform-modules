provider "aws" {
  version = "~> 1.5"
  region = "${var.region}"
}

provider "template" {
  version = "~> 1.0"
}

terraform {
  backend "s3" { }
}

data "aws_vpc" "selected" {
  tags {
    Name = "${var.identifier}-${var.environment}"
  }
}

data "aws_subnet_ids" "selected" {
  vpc_id = "${data.aws_vpc.selected.id}"

  tags {
    Tier = "${var.public ? "public" : "private"}"
  }
}

data "aws_security_group" "selected" {
  tags {
    Name = "${var.identifier}-${var.environment}-${var.role}"
  }
}

data "aws_iam_instance_profile" "selected" {
  name = "${var.identifier}-${var.environment}-${var.role}"
}

data "aws_route53_zone" "selected" {
  name = "${var.identifier}-${var.environment}.${var.region}.aws."
  private_zone = true
}

data "aws_route53_zone" "public" {
  name = "${var.public_zone}"

  count = "${var.public_zone != "" ? 1 : 0}"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/scripts/userdata.sh")}"

  vars {
    ansible_key = "${file("${path.module}/scripts/ansible.key")}"
    ansible = "${var.ansible}"

    hostname = "${var.role}-${var.environment}"
    role = "${var.role}"
    environment = "${var.environment}"
    region = "${var.region}"
    identifier = "${var.identifier}"
  }
}

resource "aws_instance" "this" {
  ami = "${var.ami}"
  instance_type = "${var.type}"

  key_name = "${var.key}"

  subnet_id = "${element(data.aws_subnet_ids.selected.ids, count.index)}"
  vpc_security_group_ids = [ "${data.aws_security_group.selected.id}" ]

  iam_instance_profile = "${data.aws_iam_instance_profile.selected.name}"

  user_data = "${data.template_file.user_data.rendered}"

  count = "${var.nodes}"

  lifecycle {
    ignore_changes = [ "tags" ]
  }

  tags {
    Cluster = "${var.environment}-${var.role}"
    Environment = "${var.environment}"
  }
}

resource "aws_eip" "this" {
  instance = "${element(aws_instance.this.*.id, count.index)}"
  vpc = true

  count = "${var.public ? "${var.nodes}" : "0"}"
}

resource "aws_route53_record" "this" {
  zone_id = "${data.aws_route53_zone.selected.id}"

  name = "${var.role}-${count.index + 1}"
  type = "A"
  ttl = "30"

  records = [ "${element(aws_instance.this.*.private_ip, count.index)}" ]

  count = "${var.nodes}"
}

resource "aws_route53_record" "public" {
  zone_id = "${data.aws_route53_zone.public_zone.id}"

  name = "${var.role}-${var.environment}-${count.index + 1}"
  type = "A"
  ttl = "30"

  records = [ "${element(aws_eip.this.*.public_ip, count.index)}" ]

  count = "${var.public_zone != "" ? var.nodes : 0}"
}

resource "aws_route53_record" "etcd" {
  zone_id = "${data.aws_route53_zone.selected.id}"

  name = "etcd-${count.index + 1}"
  type = "A"
  ttl = "30"

  records = [ "${element(aws_instance.this.*.private_ip, count.index)}" ]

  count = "${var.etcd ? var.nodes : 0}"
}

resource "aws_route53_record" "etcd-server" {
  zone_id = "${data.aws_route53_zone.selected.id}"

  name = "_etcd-server._tcp"
  type = "SRV"
  ttl = "30"

  records = [ "${formatlist("0 0 2380 %s", aws_route53_record.etcd.*.fqdn)}" ]

  count = "${var.etcd ? 1 : 0}"
}

resource "aws_route53_record" "etcd-client" {
  zone_id = "${data.aws_route53_zone.selected.id}"

  name = "_etcd-client._tcp"
  type = "SRV"
  ttl = "30"

  records = [ "${formatlist("0 0 2379 %s", aws_route53_record.etcd.*.fqdn)}" ]

  count = "${var.etcd ? 1 : 0}"
}
