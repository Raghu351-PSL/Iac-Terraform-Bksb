# main.tf

provider "aws" {
  region = var.region
}

# 1. Security Group for ECS Task
resource "aws_security_group" "ecs_task_sg" {
  name        = "new-ecs-task-sg"
  description = "Security group for ECS tasks"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. CloudWatch Logs for ECS Task
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = var.aws_log_group
}

# 3. IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_execution_role" {
  name               = "new-ecs-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect    = "Allow"
      },
    ]
  })
}

# 4. IAM Role for ECS Task (Permissions)
resource "aws_iam_role" "ecs_task_role" {
  name               = "new-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect    = "Allow"
      },
    ]
  })
}

# 5. ECS Task Definition
resource "aws_ecs_task_definition" "bksb_builder_task" {
  family                   = var.task_definition_family
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([{
    name      = "new-bksb-builder"
    image     = var.container_image
    cpu       = var.cpu
    memory    = var.memory
    essential = true

    portMappings = [
      {
        containerPort = 80
        protocol      = "tcp"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
        awslogs-stream-prefix = "new-bksb-builder"
        awslogs-region        = var.region
      }
    }

    environment = flatten([for key, value in var.environment_variables : {
      name  = key
      value = value
    }])
  }])
}

# 6. ECS Service
resource "aws_ecs_service" "bksb_builder_service" {
  name            = "new-bksb-builder-service"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.bksb_builder_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = var.security_group_ids
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.bksb_cloudmap_service.arn
  }
}
# 7. CloudMap Service
resource "aws_service_discovery_service" "bksb_cloudmap_service" {
  name = var.cloudmap_service_name

  dns_config {
    dns_records {
      ttl  = 60
      type = "A"
    }
    namespace_id = var.cloudmap_namespace_id
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# 8. SSM Parameter for Bootstrap Version
resource "aws_ssm_parameter" "bootstrap_version" {
  name        = "/cdk-bootstrap/hnb659fds/version"
  type        = "String"
  value       = "6"
  description = "Version of the CDK Bootstrap resources in this environment."
}

# Output ECS Service name and task definition family
output "ecs_service_name" {
  value = aws_ecs_service.bksb_builder_service.name
}

output "ecs_task_definition" {
  value = aws_ecs_task_definition.bksb_builder_task.family
}
 