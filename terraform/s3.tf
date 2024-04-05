locals {
  bucket_name = "levio-demo-fev-esta-ses-bucket-dev"
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

resource "aws_s3_object" "examplebucket_object" {
  key    = "formulaire/standard/formulaire.docx"
  bucket = module.s3_bucket.s3_bucket_id
  source = "formulaire.docx"
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
    lambda_function_arn = module.attachment_saver.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "formulaire/email/"
  }

  lambda_function {
    lambda_function_arn = module.resume_request_preprocessor.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "resume/transcription/"
    filter_suffix       = ".txt"
  }

  lambda_function {
    lambda_function_arn = module.transcription_formatter.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "resume/transcription/"
    filter_suffix       = ".json"
  }

  lambda_function {
    lambda_function_arn = module.form_request_preprocessor.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "formulaire/attachment/"
  }

  lambda_function {
    lambda_function_arn = module.attachment_saver.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "rfp/email/"
  }

  lambda_function {
    lambda_function_arn = module.rich_pdf_ingestion.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "rfp/attachment/"
  }

}
