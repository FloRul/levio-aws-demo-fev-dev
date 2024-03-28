variable "lambda_function_name" {
  type     = string
  nullable = false
}

variable "lambda_storage_bucket" {
  type     = string
  nullable = false
}

variable "ses_bucket_name" {
  type     = string
  nullable = false
}

variable "ses_bucket_arn" {
  type     = string
  nullable = false
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}