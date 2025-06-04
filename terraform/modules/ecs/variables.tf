variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "environment" {
  description = "The environment of the ECS cluster"
  type        = string
}

variable "load_balancer_security_group_id" {
  description = "The ID of the security group for the load balancer"
  type        = string
}

variable "task_family" { 
  type = string 
}

variable "cpu" {
  type = string 
}

variable "memory" { 
  type = string 
}

variable "container_name" { 
  type = string 
}

variable "container_image" { 
  type = string 
}

variable "container_port" { 
  type = number 
}

variable "environment_variables" { 
  type = list(object({ name = string, value = string })) 
  default = [] 
}

variable "service_name" { 
  type = string 
}

variable "desired_count" { 
  type = number 
}

variable "private_subnet_ids" { 
  type = list(string) 
}

variable "target_group_arn" { 
  type = string 
}