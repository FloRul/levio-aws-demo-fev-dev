data "aws_caller_identity" "current" {}

module "lambda_function_container_image" {
  timeout                  = 60
  source                   = "terraform-aws-modules/lambda/aws"
  handler                  = "com.levio.awsdemo.formrequestpreprocessor.App::handleRequest"
  runtime                  = "java17"
  function_name            = var.lambda_function_name
  create_package           = false
  memory_size              = 1024
  role_name                = "${var.lambda_function_name}-role"
  attach_policy_statements = true
  local_existing_package   = "${path.module}/../target/form-request-preprocessor-1.0.jar"
  s3_bucket                = var.lambda_storage_bucket


  environment_variables = {
    QUEUE_URL = var.queue_url
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
        var.ses_bucket_arn,
        "${var.ses_bucket_arn}/*"
      ]
    }

    request_sqs = {
      effect = "Allow"
      actions = [
        "sqs:SendMessage",
      ]
      resources = [
        var.request_queue_arn
      ]
    }

  }

  create_current_version_allowed_triggers = false

  allowed_triggers = {
    s3 = {
      principal  = "s3.amazonaws.com"
      source_arn = var.ses_bucket_arn
    }
  }

}
