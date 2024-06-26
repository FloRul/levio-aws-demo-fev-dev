data "aws_caller_identity" "current" {}

module "lambda_function_container_image" {
  timeout                = 60
  source                 = "terraform-aws-modules/lambda/aws"
  function_name          = var.lambda_function_name
  runtime                = "java17"
  handler                = "com.levio.awsdemo.emailresponseprocessor.App::handleRequest"
  create_package         = false
  memory_size            = 1024
  role_name              = "${var.lambda_function_name}-role"
  s3_bucket              = var.lambda_storage_bucket
  local_existing_package = "${path.module}/../target/email-response-processor-1.0.jar"


  attach_policy_statements = true

  environment_variables = {
    SENDER_EMAIL = var.sender_email
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

    sqs = {
      effect = "Allow"
      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      resources = [
        module.fifo_sqs.queue_arn
      ]
    }

    ses = {
      effect = "Allow"
      actions = [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ]
      resources = [
        "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      ]
    }

    s3 = {
      effect = "Allow"
      actions = [
        "s3:Get*",
        "s3:List*",
        "s3:Describe*",
        "s3-object-lambda:Get*",
        "s3-object-lambda:List*"
      ]
      resources = [
        var.ses_bucket_arn,
        "${var.ses_bucket_arn}/*"
      ]
    }
  }

  create_current_version_allowed_triggers = false

  allowed_triggers = {
    sqs = {
      principal  = "sqs.amazonaws.com"
      source_arn = module.fifo_sqs.queue_arn
    }
  }

  event_source_mapping = {
    sqs = {
      event_source_arn = module.fifo_sqs.queue_arn
    }
  }
}
