locals {
  api_gateway_path_part   = "inference"
  api_gateway_http_method = "GET"
}

module "api_gateway" {
  source                                = "../../terraform/modules/api_gateway/lambda_integration"
  api_gateway_rest_api_id               = var.api_gateway_rest_api_id
  api_gateway_rest_api_root_resource_id = var.api_gateway_rest_api_root_resource_id
  api_gateway_path_part                 = local.api_gateway_path_part
  api_gateway_http_method               = local.api_gateway_http_method
  lambda_function_arn                   = module.lambda_function_container_image.lambda_function_arn
  lambda_function_name                  = var.lambda_function_name
}