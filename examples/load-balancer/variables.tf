variable "region" {
  type = string
}

variable "test_name" {
  type = string
}

variable "vpc_azs" {
  type = list(string)
}

variable "associate_alb" {
  type = bool
}

variable "associate_nlb" {
  type = bool
}
