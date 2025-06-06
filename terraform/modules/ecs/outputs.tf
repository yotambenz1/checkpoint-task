output "ecs_cluster_id" {
  value = aws_ecs_cluster.aws-ecs-cluster.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.aws-ecs-cluster.name
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}

output "ecs_service_name" {
  value = aws_ecs_service.aws-ecs-service.name
}

output "ecs_service_id" {
  value = aws_ecs_service.aws-ecs-service.id
}

output "ecs_task_execution_role_name_flask_app" {
  value = aws_iam_role.ecs_task_execution_flask_app.name
}

output "ecs_task_execution_role_name_worker_app" {
  value = aws_iam_role.ecs_task_execution_worker_app.name
}
