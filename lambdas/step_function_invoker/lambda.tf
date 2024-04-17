locals {
  lambda_function_name = "step-function-ivoker"
  ses_arn              = "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.current.account_id}"
  timeout              = 30
  runtime              = "python3.11"
  powertools_layer_arn = "arn:aws:lambda:${var.aws_region}:017000801446:layer:AWSLambdaPowertoolsPythonV2:67"
}

data "aws_caller_identity" "current" {}


module "lambda_function_container_image" {
  source = "terraform-aws-modules/lambda/aws"
  function_name = local.lambda_function_name
  handler       = "index.lambda_handler"
  publish       = true
  runtime = local.runtime
  timeout = local.timeout
  layers  = [local.powertools_layer_arn]
  source_path = "${path.module}/src"
  s3_bucket   = var.lambda_storage_bucket
  memory_size              = 256
  role_name                = "${local.lambda_function_name}-role"
  attach_policy_statements = true

  environment_variables = {
    STATE_MACHINE_ARN = var.state_machine_arn
  }

  policy_statements = {
    log_group = {
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup"
      ]
      resources = [
        "arn:aws:logs:*:*:*"
      ]
    }

    log_write = {
      effect = "Allow"
      resources = [
        "arn:aws:logs:*:*:log-group:/aws/${local.lambda_function_name}/*:*"
      ]
      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
    }

    step_functions = {
      effect    = "Allow"
      resources = ["*"]
      actions = [
        "states:ListStateMachines",
        "states:StartExecution"
      ]
    }
  }
}
