variable "identifier" {
  description = ""
}

variable "environment" {
  description = ""
}

variable "region" {
  description = ""
}

variable "role" {
  description = ""
}

variable "actions" {
  description = ""
  type = "list"
  default = [ "ec2:DescribeInstances" ]
}

variable "resources" {
  description = ""
  type = "list"
  default = [ "*" ]
}

variable "effect" {
  description = ""
  default = "Allow"
}
