locals {
  memory_lambda_name           = "levio-demo-fev-memory-dev"
  dynamo_history_table_name    = "levio-demo-fev-chat-history-dev"
  storage_bucket_name          = "levio-demo-fev-storage-dev"
  queue_name                   = "levio-demo-fev-ingestion-queue-dev"
  ingestion_lambda_name        = "levio-demo-fev-ingestion-dev"
  inference_lambda_name        = "levio-demo-fev-inference-dev"
  list_collections_lambda_name = "levio-demo-fev-list-collections-dev"
  lex_router_lambda_name       = "levio-demo-fev-lex-router-dev"
}

module "ingestion" {
  source                 = "../lambdas/ingestion"
  lambda_function_name   = local.ingestion_lambda_name
  lambda_repository_name = var.ingestion_repository_name

  // S3
  storage_bucket_name = local.storage_bucket_name
  queue_name          = local.queue_name

  // VPC
  lambda_vpc_security_group_ids = [aws_security_group.lambda_egress_all_sg.id]
  lambda_vpc_subnet_ids         = module.vpc.public_subnets

  // RDS
  pg_vector_host                 = aws_db_instance.vector_db.address
  pg_vector_port                 = aws_db_instance.vector_db.port
  pg_vector_database             = aws_db_instance.vector_db.db_name
  pg_vector_user                 = aws_db_instance.vector_db.username
  pg_vector_password_secret_name = aws_secretsmanager_secret.password.name
  secret_arn                     = aws_secretsmanager_secret.password.arn
}

module "inference" {
  source                 = "../lambdas/inference"
  lambda_function_name   = local.inference_lambda_name
  lambda_repository_name = var.inference_repository_name

  // VPC
  lambda_vpc_security_group_ids = [aws_security_group.lambda_egress_all_sg.id]
  lambda_vpc_subnet_ids         = module.vpc.public_subnets

  // RDS
  pg_vector_host                 = aws_db_instance.vector_db.address
  pg_vector_port                 = aws_db_instance.vector_db.port
  pg_vector_database             = aws_db_instance.vector_db.db_name
  pg_vector_user                 = aws_db_instance.vector_db.username
  pg_vector_password_secret_name = aws_secretsmanager_secret.password.name
  secret_arn                     = aws_secretsmanager_secret.password.arn

  // RAG
  memory_lambda_name        = local.memory_lambda_name
  dynamo_history_table_name = local.dynamo_history_table_name
  embedding_collection_name = local.storage_bucket_name

  // API Gateway
  api_gateway_rest_api_id               = aws_api_gateway_rest_api.this.id
  api_gateway_rest_api_root_resource_id = aws_api_gateway_rest_api.this.root_resource_id
  stage_name                            = aws_api_gateway_stage.this.stage_name
}

module "memory" {
  source                 = "../lambdas/conversation_memory"
  lambda_function_name   = local.memory_lambda_name
  lambda_repository_name = var.memory_repository_name

  // VPC
  lambda_vpc_security_group_ids = [aws_security_group.lambda_egress_all_sg.id]
  lambda_vpc_subnet_ids         = module.vpc.public_subnets

  aws_region = var.aws_region

  // RAG
  dynamo_history_table_name = local.dynamo_history_table_name
}

module "list_collections" {
  source                 = "../lambdas/list_collections"
  lambda_function_name   = local.list_collections_lambda_name
  lambda_repository_name = var.list_collections_repository_name

  // VPC
  lambda_vpc_security_group_ids = [aws_security_group.lambda_egress_all_sg.id]
  lambda_vpc_subnet_ids         = module.vpc.public_subnets

  aws_region = var.aws_region

  // RDS
  pg_vector_host     = aws_db_instance.vector_db.address
  pg_vector_port     = aws_db_instance.vector_db.port
  pg_vector_database = aws_db_instance.vector_db.db_name
  pg_vector_user     = "collection_embedding_reader"

  // API Gateway
  api_gateway_rest_api_id               = aws_api_gateway_rest_api.this.id
  api_gateway_rest_api_root_resource_id = aws_api_gateway_rest_api.this.root_resource_id
}

module "lex_router" {
  source                 = "../lambdas/lex_router"
  lambda_function_name   = local.lex_router_lambda_name
  lambda_repository_name = var.lex_router_repository_name
  aws_region             = var.aws_region

  // VPC
  lambda_vpc_security_group_ids = [aws_security_group.lambda_egress_all_sg.id]
  lambda_vpc_subnet_ids         = module.vpc.public_subnets

  // ENV VARS
  intent_lambda_mapping = {
    SelectCollection = local.list_collections_lambda_name
    Inference        = local.inference_lambda_name
  }
}
