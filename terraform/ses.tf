locals {
  rule_set_name       = "levio-demo-fev-esta-rule-set-dev"
  chat_rule_name      = "levio-demo-fev-esta-chat-rule-dev"
  chat_key_prefix     = "chat"
  bucket_name         = "levio-demo-fev-esta-ses-bucket-dev"
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

module "s3_bucket" {
  source                   = "terraform-aws-modules/s3-bucket/aws"
  bucket                   = local.bucket_name
  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"
  policy                   = data.aws_iam_policy_document.allow_access_from_ses.json
  attach_policy            = true
  force_destroy            = true
}

data "aws_iam_policy_document" "allow_access_from_ses" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      module.s3_bucket.s3_bucket_arn,
      "${module.s3_bucket.s3_bucket_arn}/*",
    ]
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = local.bucket_name

  lambda_function {
    lambda_function_arn = module.transcription_processor.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "resume/attachment/"
  }

  lambda_function {
    lambda_function_arn = module.attachment_saver.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "resume/email/"
  }

  lambda_function {
    lambda_function_arn = module.resume_request_preprocessor.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "resume/transcription/"
  }

}