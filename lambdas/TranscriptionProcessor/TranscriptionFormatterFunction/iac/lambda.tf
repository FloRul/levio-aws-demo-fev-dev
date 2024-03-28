data "aws_caller_identity" "current" {}

module "lambda_function_container_image" {
  timeout                  = 60
  source                   = "terraform-aws-modules/lambda/aws"
  handler                  = "com.levio.awsdemo.transcriptionformatter.App::handleRequest"
  function_name            = var.lambda_function_name
  runtime                  = "java17"
  create_package           = false
  memory_size              = 1024
  role_name                = "${var.lambda_function_name}-role"
  s3_bucket                = var.lambda_storage_bucket
  local_existing_package   = "${path.module}/../target/transcription-formatter-1.0.jar"
  attach_policy_statements = true

  environment_variables = {
    BUCKET_NAME = var.bucket_name
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
      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
      resources = [
        "arn:aws:logs:*:*:log-group:/aws/${var.lambda_function_name}/*:*"
      ]
    }

    s3 = {
      effect = "Allow"
      actions = [
        "s3:Get*",
        "s3:List*",
        "s3:Describe*",
        "s3:PutObject",
        "s3-object-lambda:Get*",
        "s3-object-lambda:List*",
        "s3-object-lambda:WriteGetObjectResponse"
      ]
      resources = [
        var.bucket_arn,
        "${var.bucket_arn}/*"
      ]
    }

  }

  create_current_version_allowed_triggers = false

  allowed_triggers = {
    s3 = {
      principal  = "s3.amazonaws.com"
      source_arn = var.bucket_arn
    }
  }

}
