output "parameter_arn" {
  value = aws_ssm_parameter.token.arn
}

output "parameter_name" {
  value = aws_ssm_parameter.token.name
} 