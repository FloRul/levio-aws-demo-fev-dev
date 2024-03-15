output "lambda_function_arn" {
  value = module.lambda_function_container_image.lambda_function_arn
}

output "queue_url" {
  value = module.fifo_sqs.queue_url
}

output "queue_arn" {
  value = module.fifo_sqs.queue_arn
}