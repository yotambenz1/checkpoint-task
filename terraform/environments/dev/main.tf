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
  target_group_port   = 5000
  lb_port             = 80
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
  cpu                 = "256"
  memory              = "512"
  environment_variables_flask_app = [
    { name = "SQS_QUEUE_URL", value = module.sqs.queue_url },
    { name = "TOKEN_PARAM_NAME", value = "/checkpoint/${var.environment}/token" },
    { name = "AWS_REGION", value = var.aws_region }
  ]
  environment_variables_worker_app = [
    { name = "SQS_QUEUE_URL", value = module.sqs.queue_url },
    { name = "S3_BUCKET", value = module.s3.bucket_name },
    { name = "AWS_REGION", value = var.aws_region },
    { name = "S3_PREFIX", value = "emails/" },
    { name = "POLL_INTERVAL", value = "10" }
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
  worker_app_role_name   = module.ecs.ecs_task_execution_role_name_worker_app
  depends_on = [ module.vpc ]
}

module "sqs" {
  source      = "../../modules/sqs"
  environment = var.environment
  flask_app_role_name   = module.ecs.ecs_task_execution_role_name_flask_app
  worker_app_role_name   = module.ecs.ecs_task_execution_role_name_worker_app
  depends_on = [ module.ecs ]
}

module "ecr" {
  source      = "../../modules/ecr"
  environment = var.environment
  depends_on = [ module.vpc ]
}

module "ssm" { # TODO: change parameter value
  source          = "../../modules/ssm"
  parameter_name  = "/checkpoint/${var.environment}/token"
  parameter_value = "$DJ!SAc$#45ex3RtYr"
  tags            = var.tags
}