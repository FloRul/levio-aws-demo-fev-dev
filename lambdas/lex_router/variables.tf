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

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "lambda_repository_name" {
  nullable = false
}

variable "intent_lambda_mapping" {
  description = <<EOF
  values for environment variables for every lexV2 
  intents that must be mapped to an existing lambda function 
  in the same network. The key is the intent name and the value is the lambda function name
  EOF
  type        = map(string)
  nullable    = false
}
