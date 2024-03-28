locals {
  memory_lambda_name                      = "levio-demo-fev-memory-dev"
  dynamo_history_table_name               = "levio-demo-fev-chat-history-dev"
  storage_bucket_name                     = "levio-demo-fev-storage-dev"
  queue_name                              = "levio-demo-fev-ingestion-queue-dev"
  ingestion_lambda_name                   = "levio-demo-fev-ingestion-dev"
  inference_lambda_name                   = "levio-demo-fev-inference-dev"
  list_collections_lambda_name            = "levio-demo-fev-list-collections-dev"
  lex_router_lambda_name                  = "levio-demo-fev-lex-router-dev"
  email_request_preprocessor_lambda_name  = "levio-demo-fev-email-request-preprocessor-dev"
  email_request_processor_lambda_name     = "levio-demo-fev-email-request-processor-dev"
  email_request_processor_queue_name      = "levio-demo-fev-email-request-processor-queue-dev"
  email_response_processor_lambda_name    = "levio-demo-fev-email-response-processor-dev"
  email_response_processor_queue_name     = "levio-demo-fev-email-response-processor-queue-dev"
  attachment_saver_lambda_name            = "levio-demo-fev-attachment-saver-dev"
  transcription_processor_lambda_name     = "levio-demo-fev-transcription-processor-dev"
  resume_lambda_name                      = "levio-demo-fev-resume-dev"
  resume_request_processor_lambda_name    = "levio-demo-fev-resume-request-processor-dev"
  resume_request_preprocessor_lambda_name = "levio-demo-fev-resume-request-preprocessor-dev"
  form_request_preprocessor_lambda_name   = "levio-demo-fev-form-request-preprocessor-dev"
  transcription_formatter_lambda_name     = "levio-demo-fev-transcription-formatter-dev"
  resume_request_processor_queue_name     = "levio-demo-fev-resume-request-processor-queue-dev"
  form_request_processor_queue_name       = "levio-demo-fev-form-request-processor-queue-dev"
  form_request_processor_lambda_name      = "levio-demo-fev-form-request-processor-dev"
}

module "ingestion" {
  source              = "../lambdas/ingestion"
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
  lambda_repository_name         = var.ingestion_repository_name
  lambda_function_name           = local.ingestion_lambda_name
  queue_name                     = local.queue_name
}

module "inference" {
  source = "../lambdas/inference"
  lambda_vpc_security_group_ids = [
    aws_security_group.lambda_egress_all_sg.id,
  ]
  lambda_vpc_subnet_ids                 = module.vpc.public_subnets
  pg_vector_host                        = aws_db_instance.vector_db.address
  pg_vector_port                        = aws_db_instance.vector_db.port
  pg_vector_database                    = aws_db_instance.vector_db.db_name
  pg_vector_user                        = aws_db_instance.vector_db.username
  pg_vector_password_secret_name        = aws_secretsmanager_secret.password.name
  secret_arn                            = aws_secretsmanager_secret.password.arn
  lambda_repository_name                = var.inference_repository_name
  lambda_function_name                  = local.inference_lambda_name
  memory_lambda_name                    = local.memory_lambda_name
  dynamo_history_table_name             = local.dynamo_history_table_name
  embedding_collection_name             = local.storage_bucket_name
  api_gateway_rest_api_id               = aws_api_gateway_rest_api.this.id
  api_gateway_rest_api_root_resource_id = aws_api_gateway_rest_api.this.root_resource_id
  authorizer_id                         = aws_api_gateway_authorizer.this.id
}

module "memory" {
  source = "../lambdas/conversation_memory"
  lambda_vpc_security_group_ids = [
    aws_security_group.lambda_egress_all_sg.id,
  ]
  lambda_vpc_subnet_ids     = module.vpc.public_subnets
  aws_region                = var.aws_region
  lambda_function_name      = local.memory_lambda_name
  lambda_repository_name    = var.memory_repository_name
  dynamo_history_table_name = local.dynamo_history_table_name
}

module "list_collections" {
  source                 = "../lambdas/list_collections"
  lambda_repository_name = var.list_collections_repository_name
  lambda_vpc_security_group_ids = [
    aws_security_group.lambda_egress_all_sg.id,
  ]
  lambda_vpc_subnet_ids                 = module.vpc.public_subnets
  lambda_function_name                  = local.list_collections_lambda_name
  aws_region                            = var.aws_region
  pg_vector_host                        = aws_db_instance.vector_db.address
  pg_vector_port                        = aws_db_instance.vector_db.port
  pg_vector_database                    = aws_db_instance.vector_db.db_name
  pg_vector_user                        = "collection_embedding_reader"
  api_gateway_rest_api_id               = aws_api_gateway_rest_api.this.id
  api_gateway_rest_api_root_resource_id = aws_api_gateway_rest_api.this.root_resource_id
}

module "lex_router" {
  source = "../lambdas/lex_router"
  lambda_vpc_security_group_ids = [
    aws_security_group.lambda_egress_all_sg.id,
  ]
  lambda_vpc_subnet_ids  = module.vpc.public_subnets
  lambda_repository_name = var.lex_router_repository_name
  lambda_function_name   = local.lex_router_lambda_name
  aws_region             = var.aws_region
  intent_lambda_mapping = {
    SelectCollection = local.list_collections_lambda_name
    Inference        = local.inference_lambda_name
  }
}

module "email_response_processor" {
  source                 = "../lambdas/EmailProcessor/EmailResponseProcessorFunction/iac"
  lambda_function_name   = local.email_response_processor_lambda_name
  lambda_repository_name = var.email_response_processor_lambda_repository_name
  sqs_name               = local.email_response_processor_queue_name
  sender_email           = var.sender_email
  ses_bucket_arn         = module.s3_bucket.s3_bucket_arn
}

module "email_request_processor" {
  source                 = "../lambdas/EmailProcessor/EmailRequestProcessorFunction/iac"
  lambda_function_name   = local.email_request_processor_lambda_name
  lambda_repository_name = var.email_request_processor_lambda_repository_name
  sqs_name               = local.email_request_processor_queue_name
  api_key                = aws_api_gateway_api_key.this.value
  api_url                = "${aws_api_gateway_deployment.this.invoke_url}${aws_api_gateway_stage.this.stage_name}/${module.inference.path_part}"
  response_queue_url     = module.email_response_processor.queue_url
  response_queue_arn     = module.email_response_processor.queue_arn
}

module "email_request_preprocessor" {
  source                = "../lambdas/EmailProcessor/EmailRequestPreProcessorFunction/iac"
  lambda_function_name  = local.email_request_preprocessor_lambda_name
  ses_bucket_name       = local.bucket_name
  chat_key_prefix       = local.chat_key_prefix
  request_queue_url     = module.email_request_processor.queue_url
  request_queue_arn     = module.email_request_processor.queue_arn
  ses_s3_arn            = module.s3_bucket.s3_bucket_arn
  rule_set_name         = local.rule_set_name
  chat_rule_name        = local.chat_rule_name
  lambda_storage_bucket = aws_s3_bucket.lambda_storage.id
}

module "attachment_saver" {
  source                = "../lambdas/AttachmentSaver/AttachmentSaverFunction/iac"
  lambda_function_name  = local.attachment_saver_lambda_name
  ses_bucket_name       = local.bucket_name
  ses_bucket_arn        = module.s3_bucket.s3_bucket_arn
  lambda_storage_bucket = aws_s3_bucket.lambda_storage.id
}

module "transcription_processor" {
  source                 = "../lambdas/TranscriptionProcessor/TranscriptionFunction/iac"
  lambda_function_name   = local.transcription_processor_lambda_name
  lambda_repository_name = var.transcription_processor_lambda_repository_name
  ses_bucket_name        = local.bucket_name
  ses_bucket_arn         = module.s3_bucket.s3_bucket_arn
}

module "resume" {
  source                 = "../lambdas/ResumeProcessor/ResumeFunction/iac"
  lambda_function_name   = local.resume_lambda_name
  lambda_repository_name = var.resume_lambda_repository_name
  prompt_default         = var.prompt_default
}

module "resume_request_processor" {
  source                 = "../lambdas/ResumeProcessor/ResumeRequestProcessorFunction/iac"
  lambda_function_name   = local.resume_request_processor_lambda_name
  lambda_repository_name = var.resume_request_processor_lambda_repository_name
  ses_bucket_name        = local.bucket_name
  ses_bucket_arn         = module.s3_bucket.s3_bucket_arn
  resume_function_name   = local.resume_lambda_name
  resume_function_arn    = module.resume.lambda_function_arn
  response_queue_arn     = module.email_response_processor.queue_arn
  queue_url              = module.email_response_processor.queue_url
  dialogue_prompt        = var.dialogue_prompt
  resume_prompt          = var.resume_prompt
  sqs_name               = local.resume_request_processor_queue_name
}

module "resume_request_preprocessor" {
  source                 = "../lambdas/ResumeProcessor/ResumeRequestPreProcessorFunction/iac"
  lambda_function_name   = local.resume_request_preprocessor_lambda_name
  lambda_repository_name = var.resume_request_preprocessor_lambda_repository_name
  ses_bucket_arn         = module.s3_bucket.s3_bucket_arn
  request_queue_arn      = module.resume_request_processor.queue_arn
  queue_url              = module.resume_request_processor.queue_url
}

module "transcription_formatter" {
  source                 = "../lambdas/TranscriptionProcessor/TranscriptionFormatterFunction/iac"
  lambda_function_name   = local.transcription_formatter_lambda_name
  lambda_repository_name = var.transcription_formatter_lambda_repository_name
  bucket_name            = local.bucket_name
  bucket_arn             = module.s3_bucket.s3_bucket_arn
}

module "form_request_processor" {
  source                 = "../lambdas/FormProcessor/FormRequestProcessorFunction/iac"
  lambda_function_name   = local.form_request_processor_lambda_name
  lambda_storage_bucket = aws_s3_bucket.lambda_storage.id
  ses_bucket_name        = local.bucket_name
  ses_bucket_arn         = module.s3_bucket.s3_bucket_arn
  resume_function_name   = local.resume_lambda_name
  resume_function_arn    = module.resume.lambda_function_arn
  response_queue_arn     = module.email_response_processor.queue_arn
  queue_url              = module.email_response_processor.queue_url
  master_prompt          = var.master_prompt
  sqs_name               = local.form_request_processor_queue_name
}

module "form_request_preprocessor" {
  source                 = "../lambdas/FormProcessor/FormRequestPreProcessorFunction/iac"
  lambda_function_name   = local.form_request_preprocessor_lambda_name
  lambda_storage_bucket = aws_s3_bucket.lambda_storage.id
  ses_bucket_arn         = module.s3_bucket.s3_bucket_arn
  request_queue_arn      = module.form_request_processor.queue_arn
  queue_url              = module.form_request_processor.queue_url
}

module "email_receipt_confirmation" {
  source                = "../lambdas/email_receipt_confirmation"
  lambda_storage_bucket = aws_s3_bucket.lambda_storage.id
  aws_region            = var.aws_region
}
