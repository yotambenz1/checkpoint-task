output "alb_arn" {
  value = aws_alb.application_load_balancer.arn
}

output "alb_dns_name" {
  value = aws_alb.application_load_balancer.dns_name
}

output "alb_security_group_id" {
  value = aws_security_group.load_balancer_security_group.id
}

output "alb_security_group_arn" {
  value = aws_security_group.load_balancer_security_group.arn
}

output "alb_security_group_name" {
  value = aws_security_group.load_balancer_security_group.name
}

output "target_group_arn" {
  value = aws_lb_target_group.target_group.arn
}

output "target_group_id" {
  value = aws_lb_target_group.target_group.id
}