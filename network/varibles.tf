variable "identifier" {
  description = ""
}

variable "environment" {
  description = ""
}

variable "region" {
  description = ""
}

variable "cidr" {
  description = ""
  default = ""
}

variable "domain_name_servers" {
  description = ""
  default = [ ]
}

variable "availability_zones" {
  description = ""
  default = [ ]
}

variable "private_subnets" {
  description = ""
  default = [ ]
}

variable "public_subnets" {
  description = ""
  default = [ ]
}
