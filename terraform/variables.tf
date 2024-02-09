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
