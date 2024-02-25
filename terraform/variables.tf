variable "aws_region" {
  default = "us-east-1"
}
variable "db_admin_user" {
  default = "postgres_admin"
}
variable "db_name" {
  default = "vector_db_dev"
}
variable "jumpbox_instance_type" {
  default = "t2.micro"
}

variable "ingestion_repository_name" {
  type     = string
  nullable = false
}
variable "inference_repository_name" {
  type     = string
  nullable = false
}

variable "memory_repository_name" {
  type     = string
  nullable = false
}

variable "list_collections_repository_name" {
  type     = string
  nullable = false
}

variable "lex_router_repository_name" {
  type     = string
  nullable = false
}

variable "email_request_processor_lambda_repository_name" {
  type     = string
  nullable = false
}

variable "email_response_processor_lambda_repository_name" {
  type     = string
  nullable = false
}

variable "api_name" {
  default = "levio-demo-fev-api"
  type    = string
}

variable "api_gateway_stage_name" {
  default     = "dev"
  description = "The Api Gateway stage name"
  nullable    = false
  type        = string
}

variable "sender_email" {
  type     = string
  nullable = false
}