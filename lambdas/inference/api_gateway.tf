# locals {
#   api_gateway_path_part   = "inference"
#   api_gateway_http_method = "GET"
#   api_gateway_stage_name  = "dev"
# }

# module "api_gateway" {
#   source                  = "../terraform/modules/api_gateway"
#   api_gateway_path_part   = local.api_gateway_path_part
#   api_gateway_http_method = local.api_gateway_http_method
#   api_gateway_stage_name  = local.api_gateway_stage_name
#   lambda_function_arn     = module.lambda_function_container_image.lambda_function_arn
#   lambda_function_name    = var.lambda_function_name
# }
