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
  count = "${length(var.security)}"

  tags {
    Name = "${var.identifier}-${var.environment}-${element(var.security, count.index)}"
  }
}

data "aws_iam_instance_profile" "selected" {
  name = "${var.identifier}-${var.environment}-${var.role}"
}

data "aws_route53_zone" "selected" {
  name = "${var.identifier}-${var.environment}.${var.region}.aws."
  private_zone = true
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

resource "aws_placement_group" "this" {
  name = "${var.identifier}-${var.environment}-${var.name}"
  strategy = "${var.strategy}"
}

resource "aws_launch_configuration" "this" {
  name = "${var.identifier}-${var.environment}-${var.name}"

  image_id = "${var.ami}"
  instance_type = "${var.type}"
  key_name = "${var.key}"

  iam_instance_profile = "${aws_iam_instance_profile.selected.name}"
  security_groups = [ "${data.aws_security_group.selected.*.id}" ]

  user_data = "${data.template_file.user_data.rendered}"
}

resource "aws_autoscaling_group" "this" {
  name = "${var.identifier}-${var.environment}-${var.name}"

  min_size = "${var.min}"
  max_size = "${var.max}"

  vpc_zone_identifier = [ "${data.aws_security_group.selected.*.id}" ]

  placement_group = "${aws_placement_group.this.id}"
  launch_configuration = "${aws_launch_configuration.this.name}"

  termination_policies = [ "OldestInstance" ]

  initial_lifecycle_hook {
    name = "${var.identifier}-${var.environment}-${var.name}-initial"

    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
    default_result = "CONTINUE"
  }
}

resource "aws_autoscaling_policy" "this" {
  name = "${var.identifier}-${var.environment}-${var.name}"

  autoscaling_group_name = "${aws_autoscaling_group.this.name}"

  scaling_adjustment = "${var.adjustment}"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "${var.metric}"
    }
    target_value = "${var.metric_value}"
  }
}
