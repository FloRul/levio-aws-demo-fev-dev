data "aws_caller_identity" "current" {}

module "lambda_function_container_image" {
  timeout                  = 60
  source                   = "terraform-aws-modules/lambda/aws"
  handler                  = "com.levio.awsdemo.emailrequestpreprocessor.App::handleRequest"
  runtime                  = "java17"
  function_name            = var.lambda_function_name
  create_package           = false
  memory_size              = 1024
  role_name                = "${var.lambda_function_name}-role"
  attach_policy_statements = true
  s3_bucket                = var.lambda_storage_bucket


  environment_variables = {
    BUCKET_NAME = var.ses_bucket_name
    KEY_PREFIX  = var.chat_key_prefix
    QUEUE_URL   = var.request_queue_url
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

    request_sqs = {
      effect = "Allow"
      actions = [
        "sqs:SendMessage",
      ]
      resources = [
        var.request_queue_arn
      ]
    }

    s3 = {
      effect = "Allow"
      actions = [
        "s3:Get*",
        "s3:List*",
        "s3:Describe*",
        "s3-object-lambda:Get*",
        "s3-object-lambda:List*",
        "s3-object-lambda:WriteGetObjectResponse",
      ]
      resources = [
        var.ses_s3_arn,
        "${var.ses_s3_arn}/*"
      ]
    }
  }

  create_current_version_allowed_triggers = false

  allowed_triggers = {
    ses = {
      principal  = "ses.amazonaws.com"
      source_arn = "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.current.account_id}:receipt-rule-set/${var.rule_set_name}:receipt-rule/${var.chat_rule_name}"
    }
  }

}
