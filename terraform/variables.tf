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
  type    = string
}

variable "resume_rule_recipient" {
  default = "resume@lab.levio.cloud"
  type    = string
}

variable "form_rule_recipient" {
  default = "formulaire@lab.levio.cloud"
  type    = string
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

variable "form_request_preprocessor_lambda_repository_name" {
  type     = string
  nullable = false
}

variable "transcription_formatter_lambda_repository_name" {
  type     = string
  nullable = false
}

variable "form_request_processor_lambda_repository_name" {
  type     = string
  nullable = false
}

variable "prompt_default" {
  default = "Refais ce texte sous forme de dialogues entre un intervenant et ses clients: "
  type    = string
}

variable "dialogue_prompt" {
  default = "Refais ce texte sous forme de dialogues entre un intervenant et ses clients: "
  type    = string
}

variable "resume_prompt" {
  default = "Tu es un travailleur social. Fais une analyse de ce texte. Ne résume pas trop, permets toi d'avoir du contenu pour soutenir ta réponse"
  type    = string
}

variable "master_prompt" {
  default = "Agis comme un professionnel de la santé, soit un travailleur social. Tu as en main la transcription des échanges entre toi et les représentants d’une personne. Ton travail est de répondre aux questions posées afin de produire un mandat d’inaptitude. Répond qu’à partir des transcriptions, ne résume pas les questions dans tes réponses. Ne débute pas tes réponses par une reformulation de la question. Dans ta réponse, fait état que des points importants et précis liés à la question et assure toi que les transcriptions fournis contiennent de l'information précise pouvant répondre à cette question. Si ce n’est pas le cas, répond ceci « les transcriptions reçues ne permettent pas de répondre à cette question ». Répond en français."
  type    = string
}