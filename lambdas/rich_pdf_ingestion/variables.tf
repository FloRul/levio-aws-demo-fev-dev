variable "aws_region" {
  type     = string
  nullable = false
}

variable "lambda_repository_name" {
  type     = string
  nullable = false
}

variable "ses_bucket_arn" {
  type     = string
  nullable = false
}