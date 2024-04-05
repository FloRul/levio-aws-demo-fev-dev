locals {
  lambda_function_name = "rich_pdf_ingestion"
  ses_arn              = "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.current.account_id}"
  timeout              = 30
}

data "aws_caller_identity" "current" {}

data "aws_ecr_image" "lambda_image" {
  repository_name = var.lambda_repository_name
  most_recent     = true
}


module "lambda_function_container_image" {
  source                   = "terraform-aws-modules/lambda/aws"
  function_name            = local.lambda_function_name
  publish                  = true
  timeout                  = local.timeout
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
}
