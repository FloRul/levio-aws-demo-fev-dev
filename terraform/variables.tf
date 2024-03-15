variable "aws_region" {
  default = "us-east-1"
}
variable "db_admin_user" {
  default = "postgres_admin"
}
variable "db_name" {
  default = "vector_db_dev"
}
variable "jumpbox_instance_type" {
  default = "t2.micro"
}

variable "ingestion_repository_name" {
  type     = string
  nullable = false
}
variable "inference_repository_name" {
  type     = string
  nullable = false
}

variable "memory_repository_name" {
  type     = string
  nullable = false
}

variable "list_collections_repository_name" {
  type     = string
  nullable = false
}

variable "lex_router_repository_name" {
  type     = string
  nullable = false
}

variable "email_request_processor_lambda_repository_name" {
  type     = string
  nullable = false
}

variable "email_response_processor_lambda_repository_name" {
  type     = string
  nullable = false
}

variable "email_request_preprocessor_lambda_repository_name" {
  type     = string
  nullable = false
}

variable "api_name" {
  default = "levio-demo-fev-api"
  type    = string
}

variable "api_gateway_stage_name" {
  default     = "dev"
  description = "The Api Gateway stage name"
  nullable    = false
  type        = string
}

variable "sender_email" {
  type     = string
  nullable = false
}

variable "chat_rule_recipient" {
  default = "chat@lab.levio.cloud"
  type     = string
}

variable "resume_rule_recipient" {
  default = "resume@lab.levio.cloud"
  type     = string
}

variable "attachment_saver_lambda_repository_name" {
  type     = string
  nullable = false
}

variable "transcription_processor_lambda_repository_name" {
  type     = string
  nullable = false
}

variable "resume_lambda_repository_name" {
  type     = string
  nullable = false
}

variable "resume_request_processor_lambda_repository_name" {
  type     = string
  nullable = false
}

variable "resume_request_preprocessor_lambda_repository_name" {
  type     = string
  nullable = false
}

variable "prompt_default" {
  default  = "Refais ce texte sous forme de dialogues entre un intervenant et ses clients: "
  type     = string
}

variable "dialogue_prompt" {
  default  = "Refais ce texte sous forme de dialogues entre un intervenant et ses clients: "
  type     = string
}

variable "resume_prompt" {
  default  = "Tu es un travailleur social. Fais une analyse de ce texte. Ne résume pas trop, permets toi d'avoir du contenu pour soutenir ta réponse"
  type     = string
}