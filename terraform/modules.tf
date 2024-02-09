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
  source              = "../ingestion"
  storage_bucket_name = local.storage_bucket_name
  lambda_vpc_security_group_ids = [
    aws_security_group.lambda_egress_all_sg.id,
  ]
  lambda_vpc_subnet_ids          = module.vpc.public_subnets
  pg_vector_host                 = aws_db_instance.vector_db.address
  pg_vector_port                 = aws_db_instance.vector_db.port
  pg_vector_database             = aws_db_instance.vector_db.db_name
  pg_vector_user                 = aws_db_instance.vector_db.username
  pg_vector_password_secret_name = aws_secretsmanager_secret.password.name
  secret_arn                     = aws_secretsmanager_secret.password.arn
  lambda_image_uri               = var.ingestion_lambda_image_uri
  lambda_function_name           = local.ingestion_lambda_name
  queue_name                     = local.queue_name
}

module "inference" {
  source = "../inference"
  lambda_vpc_security_group_ids = [
    aws_security_group.lambda_egress_all_sg.id,
  ]
  lambda_vpc_subnet_ids          = module.vpc.public_subnets
  pg_vector_host                 = aws_db_instance.vector_db.address
  pg_vector_port                 = aws_db_instance.vector_db.port
  pg_vector_database             = aws_db_instance.vector_db.db_name
  pg_vector_user                 = aws_db_instance.vector_db.username
  pg_vector_password_secret_name = aws_secretsmanager_secret.password.name
  secret_arn                     = aws_secretsmanager_secret.password.arn
  lambda_image_uri               = var.inference_lambda_image_uri
  lambda_function_name           = local.inference_lambda_name
  memory_lambda_name             = local.memory_lambda_name
  dynamo_history_table_name      = local.dynamo_history_table_name
  embedding_collection_name      = local.storage_bucket_name
}

module "memory" {
  source = "../conversation_memory"
  lambda_vpc_security_group_ids = [
    aws_security_group.lambda_egress_all_sg.id,
  ]
  lambda_vpc_subnet_ids     = module.vpc.public_subnets
  aws_region                = var.aws_region
  lambda_function_name      = local.memory_lambda_name
  lambda_image_uri          = var.memory_lambda_image_uri
  dynamo_history_table_name = local.dynamo_history_table_name
}

module "list_collections" {
  source           = "../list_collections"
  lambda_image_uri = var.list_collections_lambda_image_uri
  lambda_vpc_security_group_ids = [
    aws_security_group.lambda_egress_all_sg.id,
  ]
  lambda_vpc_subnet_ids = module.vpc.public_subnets
  lambda_function_name  = local.list_collections_lambda_name
  aws_region            = var.aws_region
  pg_vector_host        = aws_db_instance.vector_db.address
  pg_vector_port        = aws_db_instance.vector_db.port
  pg_vector_database    = aws_db_instance.vector_db.db_name
  pg_vector_user        = "collection_embedding_reader"
}

module "lex_router" {
  source = "../lex_router"
  lambda_vpc_security_group_ids = [
    aws_security_group.lambda_egress_all_sg.id,
  ]
  lambda_vpc_subnet_ids = module.vpc.public_subnets
  lambda_image_uri      = var.lex_router_lambda_image_uri
  lambda_function_name  = local.lex_router_lambda_name
  aws_region            = var.aws_region
  intent_lambda_mapping = {
    SelectCollection = local.list_collections_lambda_name
    Inference         = local.inference_lambda_name
  }
}
