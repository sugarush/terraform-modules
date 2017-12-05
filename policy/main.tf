provider "aws" {
  version = "~> 1.5"
  region = "${var.region}"
}

terraform {
  backend "s3" { }
}

resource "aws_iam_role" "this" {
  name = "${var.identifier}-${var.environment}-${var.role}"
  path = "/instance/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "this" {
  name = "${var.identifier}-${var.environment}-${var.role}"
  path = "/instance/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.identifier}-${var.environment}-archlinux-repository",
        "arn:aws:s3:::${var.identifier}-${var.environment}-archlinux-repository/*"
      ]
    }
  ]
}
EOF
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
