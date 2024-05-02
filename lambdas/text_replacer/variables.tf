variable "lambda_storage_bucket" {
  type     = string
  nullable = false
}

variable "aws_region" {
  type     = string
  nullable = false
}

variable "allowed_s3_resources" {
  type     = list(string)
  nullable = false
  description = "values for the s3 resources that the lambda function can access"
}