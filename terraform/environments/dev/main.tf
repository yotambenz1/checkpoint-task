provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_name            = "checkpoint-${var.environment}-vpc"
  vpc_cidr           = var.vpc_cidr
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets    = ["172.23.1.0/24", "172.23.2.0/24"]
  public_subnets     = ["172.23.101.0/24", "172.23.102.0/24"]
  environment        = var.environment
  tags               = var.tags
}

module "alb" {
  source              = "../../modules/alb"
  alb_name            = "checkpoint-${var.environment}-alb"
  public_subnet_ids   = module.vpc.public_subnet_ids
  environment         = var.environment
  target_group_port   = 5000 # TODO: change to 80
  vpc_id              = module.vpc.vpc_id
  target_group_protocol = "HTTP"
  max_capacity        = 3
  min_capacity        = 1
  ecs_service_name    = module.ecs.ecs_service_name
  ecs_cluster_name    = module.ecs.ecs_cluster_name
  depends_on = [ module.ecs ]
}

module "ecs" {
  source              = "../../modules/ecs"
  vpc_id              = module.vpc.vpc_id
  environment         = var.environment
  load_balancer_security_group_id = module.alb.alb_security_group_id
  cluster_name        = "checkpoint-ecs-${var.environment}-cluster"
  task_family         = "checkpoint-ecs-${var.environment}-task"
  cpu                 = "256"
  memory              = "512"
  container_name      = "checkpoint-ecs-${var.environment}-app"
  container_image     = "your-docker-image:latest"
  container_port      = 5000
  environment_variables = [
    { name = "SQS_QUEUE_URL", value = module.sqs.queue_url },
    { name = "S3_BUCKET", value = module.s3.bucket_name }
  ]
  service_name        = "checkpoint-ecs-${var.environment}-service"
  desired_count       = 1
  private_subnet_ids  = module.vpc.private_subnet_ids
  target_group_arn    = module.alb.target_group_arn
  depends_on = [ module.vpc, module.s3, module.sqs ]
}

module "s3" {
  source      = "../../modules/s3"
  environment = var.environment
  depends_on = [ module.vpc ]
}

module "sqs" {
  source      = "../../modules/sqs"
  environment = var.environment
  depends_on = [ module.vpc ]
}

module "ssm" {
  source = "../../modules/ssm"
  parameter_name = "/myapp/token"
  parameter_value = "your-token-value"
}