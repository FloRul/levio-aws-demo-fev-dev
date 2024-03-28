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

variable "resume_function_name" {
  type     = string
  nullable = false
}

variable "resume_function_arn" {
  type     = string
  nullable = false
}

variable "queue_url" {
  type     = string
  nullable = false
}

variable "master_prompt" {
  type     = string
  nullable = false
}

variable "response_queue_arn" {
  type     = string
  nullable = false
}

variable "sqs_name" {
  type     = string
  nullable = false
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}