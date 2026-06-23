variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_pair_name" {
  type = string
}

variable "api_secret_key" {
  type      = string
  sensitive = true
}

variable "store_name" {
  type = string
}