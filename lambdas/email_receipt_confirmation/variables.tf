variable "lambda_function_name" {
  nullable = false
  type     = string
}

variable "lambda_vpc_security_group_ids" {
  type     = list(string)
  nullable = false
}

variable "lambda_vpc_subnet_ids" {
  type     = list(string)
  nullable = false
}

variable "lambda_repository_name" {
  nullable = false
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}