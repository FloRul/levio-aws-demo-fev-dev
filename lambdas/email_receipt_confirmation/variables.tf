variable "lambda_storage_bucket" {
  type     = string
  nullable = false
}

variable "aws_region" {
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