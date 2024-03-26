variable "lambda_function_name" {
  type     = string
  nullable = false
}

variable "ses_bucket_name" {
  type     = string
  nullable = false
}

variable "chat_key_prefix" {
  type     = string
  nullable = false
}

variable "request_queue_url" {
  type     = string
  nullable = false
}

variable "request_queue_arn" {
  type     = string
  nullable = false
}

variable "ses_s3_arn" {
  type     = string
  nullable = false
}

variable "rule_set_name" {
  type     = string
  nullable = false
}

variable "chat_rule_name" {
  type     = string
  nullable = false
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "lambda_storage_bucket" {
  type     = string
  nullable = false
}
