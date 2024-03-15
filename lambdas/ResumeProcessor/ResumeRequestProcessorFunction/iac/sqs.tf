module "fifo_sqs" {
  source                     = "terraform-aws-modules/sqs/aws"
  name                       = var.sqs_name
  fifo_queue                 = true
  visibility_timeout_seconds = 60
}