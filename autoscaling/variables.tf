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

variable "public" {
  description = ""
  default =  false
}

variable "security" {
  description = ""
  default = [ ]
}

variable "strategy" {
  description = ""
  default = "spread"
}

variable "min" {
  description = ""
  default = 1
}

variable "max" {
  description = ""
  default = 1
}

variable "adjustment" {
  description = ""
  default = 1
}

variable "metric" {
  description = "ASGAverageCPUUtilization, ASGAverageNetworkIn, ASGAverageNetworkOut"
  default = "ASGAverageCPUUtilization"
}

variable "metric_value" {
  description = ""
  default = 50.0
}
