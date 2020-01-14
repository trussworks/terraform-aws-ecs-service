variable "region" {
  type    = string
  default = "us-west-2"
}

variable "test_name" {
  type    = string
  default = "blahblah"
}

variable "vpc_azs" {
  type    = list(string)
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}
