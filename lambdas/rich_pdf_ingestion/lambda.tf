locals {
  lambda_function_name = "rich_pdf_ingestion"
  ses_arn              = "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.current.account_id}"
  timeout              = 30
  powertools_layer_arn = "arn:aws:lambda:${var.aws_region}:017000801446:layer:AWSLambdaPowertoolsPythonV2:67"
}

data "aws_caller_identity" "current" {}


module "lambda_function_container_image" {
  source                   = "terraform-aws-modules/lambda/aws"
  function_name            = local.lambda_function_name
  publish                  = true
  timeout                  = local.timeout
  layers                   = [local.powertools_layer_arn]
  source_path              = "${path.module}/src"
  memory_size              = 256
  role_name                = "${local.lambda_function_name}-role"
  attach_policy_statements = true

  create_package           = false
  image_uri                = data.aws_ecr_image.lambda_image.image_uri
  package_type             = "Image"

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
  }
}
