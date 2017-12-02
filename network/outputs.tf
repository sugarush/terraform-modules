output "vpc_id" {
  value = "${aws_vpc.this.id}"
}

output "cidr" {
  value = "${var.cidr}"
}

output "availability_zones" {
  value = "${var.availability_zones}"
}

output "public_subnet_ids" {
  value = "${join(",", aws_subnet.public.*.id)}"
}

output "private_subnet_ids" {
  value = "${join(",", aws_subnet.private.*.id)}"
}

output "public_route_table_id" {
  value = "${aws_route_table.public.id}"
}

output "private_route_table_id" {
  value = "${aws_route_table.private.id}"
}

output "zone_id" {
  value = "${aws_route53_zone.private.zone_id}"
}
