variable "alb_name" {
  description = "The name of the ALB"
  type        = string
}

variable "environment" {
  description = "The environment of the ALB"
  type        = string
}

variable "public_subnet_ids" {
  description = "The IDs of the public subnets"
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "target_group_port" {
  description = "The port of the target group"
  type        = number
}

variable "target_group_protocol" {
  description = "The protocol of the target group"
  type        = string
}

variable "max_capacity" {
  description = "The maximum capacity of the ASG"
  type        = number
}

variable "min_capacity" {
  description = "The minimum capacity of the ASG"
  type        = number
}

variable "ecs_service_name" {
  description = "The name of the ECS service"
  type        = string
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}
