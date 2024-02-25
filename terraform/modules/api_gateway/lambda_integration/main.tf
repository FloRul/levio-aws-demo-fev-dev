resource "aws_api_gateway_resource" "api_gateway_resource" {
  rest_api_id = var.api_gateway_rest_api_id
  parent_id   = var.api_gateway_rest_api_root_resource_id
  path_part   = var.api_gateway_path_part
}

module "cors" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = var.api_gateway_rest_api_id
  api_resource_id = aws_api_gateway_resource.api_gateway_resource.id
}

resource "aws_api_gateway_method" "api_gateway_method" {
  rest_api_id      = var.api_gateway_rest_api_id
  resource_id      = aws_api_gateway_resource.api_gateway_resource.id
  http_method      = var.api_gateway_http_method
  authorization    = var.authorization_type
  authorizer_id    = var.authorizer_id
  api_key_required = var.api_key_required
}

resource "aws_api_gateway_integration" "api_gateway_integration" {
  rest_api_id             = var.api_gateway_rest_api_id
  resource_id             = aws_api_gateway_resource.api_gateway_resource.id
  http_method             = aws_api_gateway_method.api_gateway_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations"
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway-${var.lambda_function_name}-${var.api_gateway_path_part}-${var.api_gateway_http_method}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.api_gateway_rest_api_id}/*/${aws_api_gateway_method.api_gateway_method.http_method}${aws_api_gateway_resource.api_gateway_resource.path}"
}

data "aws_caller_identity" "current" {}
