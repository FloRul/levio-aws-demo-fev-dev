locals {
  lambda_function_name = "email-receipt-confirmation-dev"
  ses_arn              = "arn:aws:ses:us-east-1:446872271111:identity/lab.levio.cloud"
}

module "lambda_function_container_image" {
  timeout                  = 30
  source                   = "terraform-aws-modules/lambda/aws"
  function_name            = local.lambda_function_name
  memory_size              = 256
  role_name                = "${local.lambda_function_name}-role"
  attach_policy_statements = true

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
        "arn:aws:logs:*:*:log-group:/aws/${loca.lambda_function_name}/*:*"
      ]

      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
    }

    ses = {
      effect    = "Allow"
      resources = [local.ses_arn]
      actions   = ["ses:SendEmail"]
    }
  }
}
