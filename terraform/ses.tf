locals {
  rule_set_name          = "levio-demo-fev-esta-rule-set-dev"
  chat_rule_name         = "levio-demo-fev-esta-chat-rule-dev"
  chat_key_prefix        = "chat"
  resume_rule_name       = "levio-demo-fev-esta-resume-rule-dev"
  resume_key_prefix      = "resume/email"
  form_rule_name         = "levio-demo-fev-esta-formulaire-rule-dev"
  form_key_prefix        = "formulaire/email"
  confirmation_rule_name = "levio-demo-fev-esta-confirmation-rule-dev"
}

resource "aws_lambda_permission" "ses" {
  action         = "lambda:InvokeFunction"
  function_name  = module.email_receipt_confirmation.lambda_function_arn
  principal      = "ses.amazonaws.com"
}

resource "aws_ses_receipt_rule_set" "main_rule_set" {
  rule_set_name = local.rule_set_name
}

resource "aws_ses_active_receipt_rule_set" "active_main_rule_set" {
  rule_set_name = aws_ses_receipt_rule_set.main_rule_set.rule_set_name
}

resource "aws_ses_receipt_rule" "chat_rule" {
  name          = local.chat_rule_name
  rule_set_name = aws_ses_receipt_rule_set.main_rule_set.rule_set_name
  recipients    = [var.chat_rule_recipient]
  enabled       = true
  scan_enabled  = true

  s3_action {
    bucket_name       = module.s3_bucket.s3_bucket_id
    object_key_prefix = local.chat_key_prefix
    position          = 1
  }

  lambda_action {
    function_arn = module.email_request_preprocessor.lambda_function_arn
    position     = 2
  }
}

resource "aws_ses_receipt_rule" "resume_rule" {
  name          = local.resume_rule_name
  rule_set_name = aws_ses_receipt_rule_set.main_rule_set.rule_set_name
  recipients    = [var.resume_rule_recipient]
  enabled       = true
  scan_enabled  = true

  s3_action {
    bucket_name       = module.s3_bucket.s3_bucket_id
    object_key_prefix = local.resume_key_prefix
    position          = 1
  }

}

resource "aws_ses_receipt_rule" "form_rule" {
  name          = local.form_rule_name
  rule_set_name = aws_ses_receipt_rule_set.main_rule_set.rule_set_name
  recipients    = [var.form_rule_recipient]
  enabled       = true
  scan_enabled  = true

  s3_action {
    bucket_name       = module.s3_bucket.s3_bucket_id
    object_key_prefix = local.form_key_prefix
    position          = 1
  }
}

resource "aws_ses_receipt_rule" "send_confirmation_rule" {
  name          = local.confirmation_rule_name
  rule_set_name = aws_ses_receipt_rule_set.main_rule_set.rule_set_name
  recipients    = [var.chat_rule_recipient, var.form_rule_recipient, var.resume_rule_recipient]
  enabled       = true
  scan_enabled  = true

  lambda_action {
    function_arn = module.email_receipt_confirmation.lambda_function_arn
    position     = 1
  }

  depends_on = [
    aws_lambda_permission.ses
  ]
}
