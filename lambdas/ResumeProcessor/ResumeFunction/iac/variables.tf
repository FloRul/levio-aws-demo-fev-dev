variable "lambda_function_name" {
  type     = string
  nullable = false
}

variable "lambda_repository_name" {
  type     = string
  nullable = false
}

variable "prompt_default" {
  type     = string
  nullable = false
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}