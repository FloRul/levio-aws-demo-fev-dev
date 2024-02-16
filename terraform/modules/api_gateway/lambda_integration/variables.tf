variable "api_gateway_rest_api_id" {
  type     = string
  nullable = false
}

variable "api_gateway_rest_api_root_resource_id" {
  type     = string
  nullable = false
}

variable "api_gateway_path_part" {
  description = "The Api Gateway path"
  nullable    = false
  type        = string
}

variable "api_gateway_http_method" {
  description = "The Api Gateway http method"
  nullable    = false
  type        = string
}

variable "lambda_function_arn" {
  description = "The Lambda Function arn"
  nullable    = false
  type        = string
}

variable "lambda_function_name" {
  description = "The Lambda Function arn"
  nullable    = false
  type        = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "authorization_type" {
  description = "The Api Gateway method authorization type"
  nullable    = false
  type        = string
  default     = "NONE"
}

variable "authorizer_id" {
  description = "The Api Gateway method authorizer id"
  nullable    = true
  type        = string
  default     = null
}

variable "api_key_required" {
  description = "The Api Gateway method api key required"
  nullable    = false
  type        = bool
  default     = false

}
