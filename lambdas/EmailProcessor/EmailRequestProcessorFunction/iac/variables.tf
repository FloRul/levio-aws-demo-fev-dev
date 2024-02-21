variable "lambda_function_name" {
  type     = string
  nullable = false
}

variable "lambda_repository_name" {
  type     = string
  nullable = false
}

variable "api_url" {
  type     = string
  nullable = false
}

variable "api_key" {
  type     = string
  nullable = false
}

variable "response_queue_url" {
  type     = string
  nullable = false
}

variable "response_queue_arn" {
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