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

  tags {
    Name = "${var.identifier}-${var.environment}-${var.role}"
    Managed = "terraform-${var.environment}"
  }
}

resource "aws_eip" "this" {
  instance = "${element(aws_instance.this.*.id, count.index)}"
  vpc = true

  count = "${var.nodes}"
}
