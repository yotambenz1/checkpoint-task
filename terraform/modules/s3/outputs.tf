output "bucket_name" {
  value = module.s3_buckets["${var.environment}"].s3_bucket_id
}

output "bucket_arn" {
  value = module.s3_buckets["${var.environment}"].s3_bucket_arn
}