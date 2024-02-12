resource "aws_api_gateway_rest_api" "this" {
  name = var.api_name
}

resource "aws_api_gateway_deployment" "this" {
  depends_on  = [module.inference, module.list_collections]
  description = "Deployment for ${timestamp()}"
  lifecycle {
    create_before_destroy = true
  }
  triggers = {
    redeployment = timestamp()
  }
  rest_api_id = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.api_gateway_stage_name
}

resource "aws_api_gateway_usage_plan" "this" {
  depends_on = [aws_api_gateway_stage.this]
  name       = "api_gateway_usage_plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = var.api_gateway_stage_name
    throttle {
      burst_limit = 50
      path        = "/inference/GET"
    }
  }

  quota_settings {
    limit  = 100
    offset = 0
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 100
    rate_limit  = 50
  }
}

resource "aws_api_gateway_api_key" "this" {
  name = "${var.api_name}-key"
}

resource "aws_api_gateway_usage_plan_key" "this" {
  key_id        = aws_api_gateway_api_key.this.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this.id
}
