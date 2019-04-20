variable "identifier" {
  description = ""
}

variable "environment" {
  description = ""
}

variable "region" {
  description = ""
}

variable "ansible" {
  description = ""
}

variable "key" {
  description = ""
}

variable "ami" {
  description = ""
}

variable "role" {
  description = ""
}

variable "iam_profile" {
  description = ""
}

variable "type" {
  description = ""
}

variable "nodes" {
  description = ""
}

variable "etcd" {
  description = ""
  default = false
}

variable "public" {
  description = ""
  default = false
}

variable "public_zone" {
  description = ""
  default = ""
}

variable "security" {
  description = ""
  default = [ ]
}

variable "volume_size" {
  description = ""
  default = "10"
}
