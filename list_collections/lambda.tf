module "lambda_function_container_image" {
  timeout                  = 30
  source                   = "terraform-aws-modules/lambda/aws"
  function_name            = var.lambda_function_name
  memory_size              = 128
  vpc_subnet_ids           = var.lambda_vpc_subnet_ids
  vpc_security_group_ids   = var.lambda_vpc_security_group_ids
  role_name                = "${var.lambda_function_name}-role"
  attach_policy_statements = true
  source_path              = "${path.module}/src"
  runtime = "python3.12"
  handler = "index.lambda_handler"
  environment_variables = {
    PGVECTOR_DRIVER   = "psycopg2"
    PGVECTOR_HOST     = var.pg_vector_host
    PGVECTOR_PORT     = var.pg_vector_port
    PGVECTOR_DATABASE = var.pg_vector_database
    PGVECTOR_USER     = var.pg_vector_user
    PGVECTOR_PASSWORD = "dbreader"
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

      resources = [
        "arn:aws:logs:*:*:log-group:/aws/${var.lambda_function_name}/*:*"
      ]

      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
    }
    rds_connect_read = {
      effect = "Allow"

      resources = [
        "arn:aws:rds:${var.aws_region}:446872271111:db:${var.pg_vector_database}"
      ]

      actions = [
        "rds-db:connect",
        "rds-db:execute-statement",
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
  }
}
