# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.cluster_name}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
}

# ECS Task Assume Role Policy
data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ECS Task Execution Policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_security_group" "service_security_group" {
  vpc_id = var.vpc_id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [var.load_balancer_security_group_id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "ecs-service-sg"
    Environment = var.environment
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "${var.cluster_name}-${var.environment}-ecs-cluster"
  tags = {
    Terraform   = true
    Environment = var.environment
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "aws-ecs-task-definition" { # TODO: overview code of task definition is correct  
  family                   = var.task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.container_image
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
      environment = var.environment_variables
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "aws-ecs-service" {
  name                 = "${var.service_name}-${var.environment}-ecs-service"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = aws_ecs_task_definition.aws-ecs-task-definition.arn
  desired_count        = var.desired_count
  force_new_deployment = true
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups = [
      aws_security_group.service_security_group.id,
      var.load_balancer_security_group_id
    ]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution_policy, aws_lb_listener.listener]
}