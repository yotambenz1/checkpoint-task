resource "aws_appautoscaling_target" "asg_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.ecs_cluster_name}/${var.ecs_service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "asg_policy_memory" {
  name               = "asg-${var.environment}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.asg_target.resource_id
  scalable_dimension = aws_appautoscaling_target.asg_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.asg_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "asg_policy_cpu" {
  name               = "asg-${var.environment}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.asg_target.resource_id
  scalable_dimension = aws_appautoscaling_target.asg_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.asg_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 80
  }
}