output "queue_url" {
  value = module.sqs_queues["${var.environment}"].queue_url
}

output "queue_arn" {
  value = module.sqs_queues["${var.environment}"].queue_arn
}

output "queue_name" {
  value = module.sqs_queues["${var.environment}"].queue_name
}

output "queue_id" {
  value = module.sqs_queues["${var.environment}"].queue_id
}