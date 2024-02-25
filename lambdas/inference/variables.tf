variable "lambda_function_name" {
  type     = string
  nullable = false
}

variable "lambda_repository_name" {
  type     = string
  nullable = false
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

variable "memory_lambda_name" {
  type     = string
  nullable = false
}

variable "dynamo_history_table_name" {
  type     = string
  nullable = false
}

variable "embedding_collection_name" {
  type     = string
  nullable = false
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "api_gateway_rest_api_id" {
  type     = string
  nullable = false
}

variable "api_gateway_rest_api_root_resource_id" {
  type     = string
  nullable = false
}

variable "cognito_user_pool_id" {
  type     = string
  nullable = false
}
