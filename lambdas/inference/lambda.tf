data "aws_ecr_image" "lambda_image" {
  repository_name = var.lambda_repository_name
  most_recent     = true
}

module "lambda_function_container_image" {
  timeout                  = 60
  source                   = "terraform-aws-modules/lambda/aws"
  function_name            = var.lambda_function_name
  create_package           = false
  image_uri                = data.aws_ecr_image.lambda_image.image_uri
  package_type             = "Image"
  memory_size              = 1024
  vpc_subnet_ids           = var.lambda_vpc_subnet_ids
  vpc_security_group_ids   = var.lambda_vpc_security_group_ids
  role_name                = "${var.lambda_function_name}-role"
  attach_policy_statements = true

  environment_variables = {
    PGVECTOR_DRIVER               = "psycopg2"
    PGVECTOR_HOST                 = var.pg_vector_host
    PGVECTOR_PORT                 = var.pg_vector_port
    PGVECTOR_DATABASE             = var.pg_vector_database
    PGVECTOR_USER                 = var.pg_vector_user
    PGVECTOR_PASSWORD_SECRET_NAME = var.pg_vector_password_secret_name
    MAX_TOKENS                    = 600
    ENABLE_INFERENCE              = 1
    ENABLE_HISTORY                = 1
    ENABLE_RETRIEVAL              = 1
    MEMORY_LAMBDA_NAME            = var.memory_lambda_name
    DYNAMO_TABLE                  = var.dynamo_history_table_name
    TOP_K                         = 10
    TEMPERATURE                   = 0.1
    TOP_P                         = 0.99
    RELEVANCE_THRESHOLD           = 0.67
    MODEL_ID                      = "anthropic.claude-instant-v1"

    SYSTEM_PROMPT            = "Answer in french."
    EMAIL_PROMPT             = "You are currently answering an email so your answer can be more detailed. After you finish answering the initial query generate follow-up questions and answer it too up to 4 questions.\n"
    CALL_PROMPT              = "Make your answer short and concise.\n"
    CHAT_PROMPT              = "You are currently answering a message.\n"
    DOCUMENT_PROMPT          = "Here is a set of quotes between <quotes></quotes> XML tags to help you answer: <quotes>{docs_context}</quotes>.\n"
    NO_DOCUMENT_FOUND_PROMPT = "You could not find any relevant quotes to help answer the user's query. Therefore just say that you cannot help furthermore with the user's query, whatever his request is.\n"
    HISTORY_PROMPT           = "Here is the history of the previous messages history between <history></history> XML tags: <history>{}</history>."
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
    bedrock_usage = {
      effect = "Allow"

      resources = [
        "*"
      ]

      actions = [
        "bedrock:*"
      ]
    }
    rds_connect_readwrite = {
      effect = "Allow"

      resources = [
        "arn:aws:rds:${var.aws_region}:446872271111:db:${var.pg_vector_database}"
      ]

      actions = [
        "rds-db:connect",
        "rds-db:execute-statement",
        "rds-db:rollback-transaction",
        "rds-db:commit-transaction",
        "rds-db:beginTransaction"
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
    secretsmanager = {
      effect = "Allow"

      resources = [
        var.secret_arn
      ]

      actions = [
        "secretsmanager:GetSecretValue"
      ]
    }
    dynamo_db = {
      effect = "Allow"

      resources = [
        "arn:aws:dynamodb:${var.aws_region}:446872271111:table/${var.dynamo_history_table_name}"
      ]

      actions = [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Scan",
        "dynamodb:Query",
        "dynamodb:BatchWriteItem",
        "dynamodb:BatchGetItem"
      ]
    }
    lambda = {
      effect = "Allow"

      resources = [
        "arn:aws:lambda:${var.aws_region}:446872271111:function:${var.memory_lambda_name}"
      ]

      actions = [
        "lambda:InvokeFunction"
      ]
    }
  }
}
