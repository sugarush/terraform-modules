resource "aws_s3_bucket" "this" {
  bucket = "${var.name}"
  region = "${var.region}"
  acl = "${var.acl}"
}
