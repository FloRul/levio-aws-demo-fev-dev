data "aws_ecr_image" "lambda_image" {
  repository_name = var.lambda_repository_name
  most_recent     = true
}

data "aws_caller_identity" "current" {}

module "lambda_function_container_image" {
  timeout                  = 300
  source                   = "terraform-aws-modules/lambda/aws"
  function_name            = var.lambda_function_name
  create_package           = false
  image_uri                = data.aws_ecr_image.lambda_image.image_uri
  package_type             = "Image"
  memory_size              = 1024
  role_name                = "${var.lambda_function_name}-role"
  attach_policy_statements = true

  environment_variables = {
    BUCKET_NAME     = var.ses_bucket_name
    FUNCTION_NAME   = var.resume_function_name
    QUEUE_URL       = var.queue_url
    DIALOGUE_PROMPT = var.dialogue_prompt
    RESUME_PROMPT   = var.resume_prompt
  }

  policy_statements = {
    log_group = {
      effect  = "Allow"
      actions = [
        "logs:CreateLogGroup"
      ]
      resources = [
        "arn:aws:logs:*:*:*"
      ]
    }

    log_write = {
      effect  = "Allow"
      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
      resources = [
        "arn:aws:logs:*:*:log-group:/aws/${var.lambda_function_name}/*:*"
      ]
    }

    s3 = {
      effect  = "Allow"
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
      effect  = "Allow"
      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      resources = [
        module.fifo_sqs.queue_arn
      ]
    }

    response_sqs = {
      effect  = "Allow"
      actions = [
        "sqs:SendMessage",
      ]
      resources = [
        var.response_queue_arn
      ]
    }

    lambda = {
      effect  = "Allow"
      actions = [
        "lambda:InvokeFunction",
      ]
      resources = [
        var.resume_function_arn
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
