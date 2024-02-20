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

  throttle_settings {
    burst_limit = 100
    rate_limit  = 50
  }

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = var.api_gateway_stage_name
  }

  quota_settings {
    limit  = 100
    offset = 0
    period = "DAY"
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

## Auth and Authorizer
resource "aws_api_gateway_authorizer" "this" {
  name                   = "${var.api_name}-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.this.id
  type = "COGNITO_USER_POOLS"
  provider_arns = [var.cognito_user_pool_arn]
}


## Logging

resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = aws_iam_role.this.arn
}

resource "aws_iam_role" "this" {
  name = "${var.api_name}-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "this" {
  name = "this"
  role = aws_iam_role.this.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents",
        "logs:GetLogEvents",
        "logs:FilterLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}