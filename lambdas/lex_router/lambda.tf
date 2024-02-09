data "aws_ecr_image" "lambda_image" {
  repository_name = var.lambda_repository_name
  most_recent     = true
}

module "lambda_function_container_image" {
  timeout                  = 30
  source                   = "terraform-aws-modules/lambda/aws"
  function_name            = var.lambda_function_name
  create_package           = false
  image_uri                = data.aws_ecr_image.lambda_image.image_uri
  memory_size              = 256
  package_type             = "Image"
  vpc_subnet_ids           = var.lambda_vpc_subnet_ids
  vpc_security_group_ids   = var.lambda_vpc_security_group_ids
  role_name                = "${var.lambda_function_name}-role"
  attach_policy_statements = true

  environment_variables = var.intent_lambda_mapping

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
        "arn:aws:logs:*:*:log-group:/aws/${var.lambda_function_name}/*:*"
      ]

      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
    }
    access_network_interface = {
      effect = "Allow"

      resources = [
        "*"
      ]

      actions = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ]
    }
    lambda = {
      effect = "Allow"

      resources = [
        "arn:aws:lambda:${var.aws_region}:446872271111:function:*"
      ]

      actions = [
        "lambda:InvokeFunction"
      ]
    }
  }
}
