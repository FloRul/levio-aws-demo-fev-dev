data "aws_caller_identity" "current" {}

module "lambda_function_container_image" {
  # source                   = "terraform-aws-modules/lambda/aws"
  # handler                  = "com.levio.awsdemo.emailrequestpreprocessor.App::handleRequest"
  # publish                  = true
  # runtime                  = "java17"
  # timeout                  = 60
  # function_name            = var.lambda_function_name
  # memory_size              = 1024
  # role_name                = "${var.lambda_function_name}-role"
  # attach_policy_statements = true
  # s3_bucket                = var.lambda_storage_bucket
  # local_existing_package   = "${path.module}/../target/email-request-preprocessor-1.0.jar"
  # create_package           = false

  timeout                  = 60
  handler                  = "com.levio.awsdemo.attachmentsaver.App::handleRequest"
  runtime                  = "java17"
  source                   = "terraform-aws-modules/lambda/aws"
  function_name            = var.lambda_function_name
  create_package           = false
  memory_size              = 1024
  role_name                = "${var.lambda_function_name}-role"
  attach_policy_statements = true
  s3_bucket                = var.lambda_storage_bucket
  local_existing_package   = "${path.module}/../target/attachment-saver-1.0.jar"

  environment_variables = {
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
  }

  create_current_version_allowed_triggers = false

  allowed_triggers = {
    s3 = {
      principal  = "s3.amazonaws.com"
      source_arn = var.ses_bucket_arn
    }
  }

}
