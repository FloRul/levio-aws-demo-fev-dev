resource "aws_api_gateway_rest_api" "api_gateway_rest_api" {
  name = "api_gateway_rest_api"
}

resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  depends_on = [module.inference, module.list_collections]

  rest_api_id = aws_api_gateway_rest_api.api_gateway_rest_api.id
}

resource "aws_api_gateway_stage" "api_gateway_stage" {
  deployment_id = aws_api_gateway_deployment.api_gateway_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api_gateway_rest_api.id
  stage_name    = var.api_gateway_stage_name
}

resource "aws_api_gateway_usage_plan" "api_gateway_usage_plan" {
  depends_on = [aws_api_gateway_stage.api_gateway_stage]
  name       = "api_gateway_usage_plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.api_gateway_rest_api.id
    stage  = var.api_gateway_stage_name
  }
}

resource "aws_api_gateway_api_key" "api_gateway_api_key" {
  name = "api_gateway_api_key"
}

resource "aws_api_gateway_usage_plan_key" "api_gateway_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.api_gateway_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.api_gateway_usage_plan.id
}