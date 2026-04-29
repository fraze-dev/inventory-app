variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "my_ip" {
  type        = string
  description = "My local IP for SSH access"
}

variable "dockerhub_username" {
  type    = string
  default = "frazedcoker"
}

variable "mongo_root_password" {
  type      = string
  sensitive = true
}

variable "mongo_express_password" {
  type      = string
  sensitive = true
}