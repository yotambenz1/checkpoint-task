resource "aws_ssm_parameter" "token" {
  name        = var.parameter_name
  description = "Token for microservice validation"
  type        = "SecureString"
  value       = var.parameter_value
  tags        = var.tags
}