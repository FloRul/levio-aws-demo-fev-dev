variable "storage_bucket_name" {
  type     = string
  nullable = false
}

variable "textract_output_bucket_name" {
  type     = string
  nullable = false
}

variable "lambda_function_name" {
  nullable = false
  type     = string
}

variable "lambda_vpc_security_group_ids" {
  type     = list(string)
  nullable = false
}

variable "lambda_vpc_subnet_ids" {
  type     = list(string)
  nullable = false
}

variable "pg_vector_host" {
  type     = string
  nullable = false
}

variable "pg_vector_port" {
  type     = number
  nullable = false
}

variable "pg_vector_database" {
  type     = string
  nullable = false
}

variable "pg_vector_user" {
  type     = string
  nullable = false
}

variable "pg_vector_driver" {
  type     = string
  nullable = false
  default  = "psycopg2"
}

variable "pg_vector_password_secret_name" {
  type     = string
  nullable = false
}

variable "secret_arn" {
  type     = string
  nullable = false
}

variable "lambda_repository_name" {
  nullable = false
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "queue_name" {
  description = "The name of the SQS queue that dispatch the files to the Lambda function"
  type        = string
  nullable    = false
}

