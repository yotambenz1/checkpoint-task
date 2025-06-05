data "aws_caller_identity" "current" {}

module "s3_buckets" {
  source = "terraform-aws-modules/s3-bucket/aws"

  for_each = toset(var.environment)

  bucket = "checkpoint-sqs-bucket-${each.key}"

  acl = "private"
  lifecycle_rule = [
    {
      id      = "noncurrent-version-rule"
      enabled = true

      noncurrent_version_transition = {
        newer_noncurrent_versions = 1
        noncurrent_days           = 7
        storage_class             = "GLACIER_IR"
      }
    },
  ]
  versioning = {
    status     = true
    mfa_delete = false
  }
  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = false

      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "s3:PutObject"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.worker_app_role_name}"
          ]
        }
        Resource = "arn:aws:s3:::${module.s3_buckets[each.key].id}/*"
      }
    ]
  })
  
  force_destroy                          = true
  transition_default_minimum_object_size = "varies_by_storage_class"
} 