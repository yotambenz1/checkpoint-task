module "sqs_queues" {
  source = "terraform-aws-modules/sqs/aws"

  for_each = toset(var.environment)

  name = "SQSToS3-${each.key}.fifo"

  fifo_queue          = true
  create_queue_policy = true
  queue_policy_statements = [
    {
      sid       = "QueuePolicy"
      effect    = "Allow"
      actions   = ["SQS:SendMessage"]
      resources = ["arn:aws:sqs:us-west-2:684736489365:SQSToS3-${each.key}.fifo"]

      principals = [
        {
          type        = "Service"
          identifiers = ["sns.amazonaws.com"]
        }
      ]

      conditions = [ # TODO: change to match the ALB ARN
        {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values   = ["arn:aws:sns:us-west-2:684736489365:sqs-to-s3-${each.key}.fifo"]
        }
      ]
    }
  ]

  redrive_policy = {
    maxReceiveCount = 10
  }

  create_dlq                      = true
  dlq_name                        = "SQSToS3-DLQ-${each.key}.fifo"
  create_dlq_queue_policy         = true
  create_dlq_redrive_allow_policy = false
  dlq_queue_policy_statements = [
    {
      sid       = "__owner_statement"
      effect    = "Allow"
      actions   = ["SQS:*"]
      resources = ["arn:aws:sqs:us-west-2:684736489365:SQSToS3-DLQ-${each.key}.fifo"]

      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::684736489365:root"]
        }
      ]
    }
  ]

  tags = {
    Environment = var.environment
  }
} 