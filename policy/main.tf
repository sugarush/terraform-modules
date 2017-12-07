provider "aws" {
  version = "~> 1.5"
  region = "${var.region}"
}

terraform {
  backend "s3" { }
}

data "aws_iam_policy_document" "role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals = {
      type = "Service"
      identifiers = [ "ec2.amazonaws.com" ]
    }
  }
}

data "aws_iam_policy_document" "policy" {
  statement {
    actions = [ "${var.actions}" ]
    resources = [ "${var.resources}" ]
  }

  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:CreateTags"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::${var.identifier}-${var.environment}-archlinux-repository",
      "arn:aws:s3:::${var.identifier}-${var.environment}-archlinux-repository/*"
    ]
  }
}

resource "aws_iam_role" "this" {
  name = "${var.identifier}-${var.environment}-${var.role}"
  path = "/instance/"
  assume_role_policy = "${data.aws_iam_policy_document.role.json}"
}

resource "aws_iam_policy" "this" {
  name = "${var.identifier}-${var.environment}-${var.role}"
  path = "/instance/"
  policy = "${data.aws_iam_policy_document.policy.json}"
}

resource "aws_iam_policy_attachment" "this" {
  name = "${var.identifier}-${var.environment}-${var.role}"
  roles = [ "${aws_iam_role.this.name}" ]
  policy_arn = "${aws_iam_policy.this.arn}"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.identifier}-${var.environment}-${var.role}"
  path = "/instance/"
  role = "${aws_iam_role.this.name}"
}
