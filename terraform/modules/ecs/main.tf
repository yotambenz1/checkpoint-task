# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.cluster_name}-task-execution-role"
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

resource "aws_security_group" "flask_app_sg" {
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
    Name        = "ecs-service-${var.environment}-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "worker_app_sg" {
  vpc_id = var.vpc_id

  # Allow all outbound traffic (to SQS, S3, etc.)
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Block all inbound traffic (optional)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  tags = {
    Name        = "worker-app-${var.environment}-sg"
    Environment = var.environment
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "${var.cluster_name}"
  tags = {
    Terraform   = true
    Environment = var.environment
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "flask_app" {
  family                   = "flask-app-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "flask-app"
      image     = "flask-app:latest"
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ]
      environment = var.environment_variables
    }
  ])
}

resource "aws_ecs_task_definition" "worker_app" {
  family                   = "worker-app-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "worker-app"
      image     = "worker-app:latest"
      environment = var.environment_variables
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "aws-ecs-service-flask-app" {
  name                 = "${var.service_name}-flask-app"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = aws_ecs_task_definition.flask_app.arn
  desired_count        = var.desired_count
  force_new_deployment = true
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups = [
      aws_security_group.flask_app_sg.id,
      var.load_balancer_security_group_id
    ]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "flask-app"
    container_port   = 5000
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution_policy, aws_ecs_task_definition.flask_app, aws_lb_listener.listener]
}

resource "aws_ecs_service" "aws-ecs-service-worker-app" {
  name                 = "${var.service_name}-worker-app"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = aws_ecs_task_definition.worker_app.arn
  desired_count        = var.desired_count
  force_new_deployment = true
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups = [
      aws_security_group.worker_app_sg.id
    ]
    assign_public_ip = false
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution_policy, aws_ecs_task_definition.worker_app]
}