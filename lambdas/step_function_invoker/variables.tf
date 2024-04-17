variable "lambda_storage_bucket" {
  type     = string
  nullable = false
}

variable "state_machine_arn" {
  type     = string
  nullable = false
}

variable "aws_region" {
  type     = string
  nullable = false
}