variable "lambda_function_name" {
  type     = string
  nullable = false
}

variable "lambda_repository_name" {
  type     = string
  nullable = false
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "sqs_name" {
  type     = string
  nullable = false
}

variable "sender_email" {
  type     = string
  nullable = false
}