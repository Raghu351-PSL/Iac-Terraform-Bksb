# AWS::EC2::SecurityGroup
resource "aws_security_group" "bksb_reforms_api_sg" {
  name        = "StageBKSBReformsAPIAppSydney/BKSBReformsAPISG"
  description = "StageBKSBReformsAPIAppSydney/BKSBReformsAPISG"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP egress rule for internet"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS egress rule for internet"
  }

  egress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["10.10.20.0/24"]
    description = "SQL Server egress rule for Database Subnet"
  }

  egress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["10.10.21.0/24"]
    description = "SQL Server egress rule for Database Subnet"
  }

  egress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.10.22.0/24"]
    description = "Redis egress rule for Redis Subnet"
  }

  egress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.10.23.0/24"]
    description = "Redis egress rule for Redis Subnet"
  }

  tags = {
    Name = "StageBKSBReformsAPIAppSydney/BKSBReformsAPISG/Resource"
  }
}

# AWS::EC2::SecurityGroupIngress
resource "aws_security_group_rule" "bksb_reforms_api_sg_ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  description              = "Load balancer to target"
  security_group_id        = aws_security_group.bksb_reforms_api_sg.id
  source_security_group_id = var.alb_security_group_id
}

# AWS::ElasticLoadBalancingV2::TargetGroup - ALBTargetGroupOne
resource "aws_lb_target_group" "alb_target_group_one" {
  name                   = "ALBTargetGroupOne"
  port                   = 443
  protocol               = "HTTPS"
  vpc_id                 = var.vpc_id
  target_type            = "ip"
  health_check {
    enabled            = true
    interval           = 20
    path               = "/api/healthCheck"
    timeout            = 10
    healthy_threshold  = 2
    unhealthy_threshold = 4
  }
  stickiness {
    enabled = false
    type    = "lb_cookie"
  }

  tags = {
    name = "StageBKSBReformsAPIAppSydney/ALBTargetGroupOne/Resource"
  }
}

# AWS::ElasticLoadBalancingV2::TargetGroup - ALBTargetGroupTwo
resource "aws_lb_target_group" "alb_target_group_two" {
  name                   = "ALBTargetGroupTwo"
  port                   = 443
  protocol               = "HTTPS"
  vpc_id                 = var.vpc_id
  target_type            = "ip"
  health_check {
    enabled            = true
    interval           = 20
    path               = "/api/healthCheck"
    timeout            = 10
    healthy_threshold  = 2
    unhealthy_threshold = 4
  }
  stickiness {
    enabled = false
    type    = "lb_cookie"
  }

  tags = {
    "Name" = "StageBKSBReformsAPIAppSydney/ALBTargetGroupTwo/Resource"
  }
}

resource "aws_lb_listener_rule" "alb_listener_rule" {
  listener_arn = var.alb_listener_prod_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group_one.arn
  }

  condition {
    path_pattern {
      values = ["/bksblive2/v5api/*"]
    }
  }
}

# AWS::IAM::Role - BKSBReformsAPIECSContainerTaskDefinitionTaskRole
resource "aws_iam_role" "ecs_task_role" {
  name = "BKSBReformsAPIECSContainerTaskDefinitionTaskRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    "Name" = "StageBKSBReformsAPIAppSydney/BKSBReformsAPIECSContainerTaskDefinition/TaskRole/Resource"
  }
}

# AWS::IAM::Policy - BKSBReformsAPIECSContainerTaskDefinitionTaskRoleDefaultPolicy
resource "aws_iam_policy" "ecs_task_role_default_policy" {
  name        = "BKSBReformsAPIECSContainerTaskDefinitionTaskRoleDefaultPolicy"
  description = "Default policy for ECS task role"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketVersions",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::bksbbuildercontentdev",
          "arn:aws:s3:::bksbbuildercontentdev/*",
          "arn:aws:s3:::bksbdevenginecontent-stage",
          "arn:aws:s3:::bksbdevenginecontent-stage/*",
          "arn:aws:s3:::staging-bksb-fargate-ireland-key",
          "arn:aws:s3:::staging-bksb-fargate-ireland-key/*"
        ]
      },
      {
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "xray:GetSamplingRules",
          "xray:GetSamplingStatisticSummaries",
          "xray:GetSamplingTargets",
          "xray:PutTelemetryRecords",
          "xray:PutTraceSegments"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_role_default_policy.arn
}


# AWS::IAM::Role - BKSBReformsAPIECSContainerTaskDefinitionExecutionRole
resource "aws_iam_role" "ecs_execution_role" {
  name = "BKSBReformsAPIECSContainerTaskDefinitionExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    "Name" = "StageBKSBReformsAPIAppSydney_c893891a06d599518928b25ea512491ba0194f52da"
    "Name" = "StageBKSBReformsAPIAppSydney/BKSBReformsAPIECSContainerTaskDefinition/ExecutionRole/Resource"
  }
}

# AWS::Logs::LogGroup - BKSBReformsAPIECSContainerTaskDefinitionBKSBReformsAPIECSContainerLogGroup
resource "aws_cloudwatch_log_group" "bksb_reforms_api_ecs_container_log_group" {
  name              = "/ecs/stage-bksb-reforms-api"
  retention_in_days = 30
  tags = {
    "Name" = "StageBKSBReformsAPIAppSydney/BKSBReformsAPIECSContainerTaskDefinition/BKSBReformsAPIECSContainer/LogGroup/Resource"
  }
}

# AWS::Logs::LogGroup - BKSBReformsAPIECSContainerTaskDefinitionBKSBLive2ReformsAPIXRayECSContainerLogGroup
resource "aws_cloudwatch_log_group" "bksb_reforms_api_xray_ecs_container_log_group" {
  name              = "/ecs/stage-bksb-reforms-api-xray"
  retention_in_days = 30
  tags = {
    "Name" = "StageBKSBReformsAPIAppSydney/BKSBLive2ReformsAPIXRayECSContainer/LogGroup/Resource"
  }
}


# AWS::IAM::Policy - BKSBReformsAPIECSContainerTaskDefinitionExecutionRoleDefaultPolicy
resource "aws_iam_policy" "ecs_execution_role_default_policy" {
  name        = "BKSBReformsAPIECSContainerTaskDefinitionExecutionRoleDefaultPolicy"
  description = "Default policy for ECS execution role"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:GetDownloadUrlForLayer"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ecr:eu-west-2:592311462240:repository/bksb/dev/bksb-reforms-service"
      },
      {
        Action   = "ecr:GetAuthorizationToken"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = [
          "${aws_cloudwatch_log_group.bksb_reforms_api_ecs_container_log_group.arn}:*",
          "${aws_cloudwatch_log_group.bksb_reforms_api_xray_ecs_container_log_group.arn}:*" 
        ]
      },
      {
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = [
          "${var.db_connection_string_secret_arn}*",
          "${var.redis_connection_string_secret_arn}*",
        ]
      },
      {
        Action   = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = [
          "${var.db_connection_string_secret_arn}*",
          "${var.redis_connection_string_secret_arn}*",
        ]
      },
      {
        Action   = "kms:Decrypt"
        Effect   = "Allow"
        Resource = var.kms_key_arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_execution_role_default_policy.arn
}

# AWS::ECS::TaskDefinition
resource "aws_ecs_task_definition" "bksb_reforms_api_task_definition" {
  family                   = "stage_bksb-reforms-api"
  cpu                      = "2048"
  memory                   = "8192"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name        = "bksb-reforms-api"
      cpu         = 2016
      memory      = 7936
      essential   = true
      image       = var.ecr_repository_url
      portMappings = [
        {
          containerPort = 443
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "ASPNETCORE_ENVIRONMENT", value = "Production" },
        { name = "ASPNETCORE_URLS", value = "https://+:443" },
        { name = "Sentry__Debug", value = "false" },
        { name = "BKSB__APP__AllowDirectLogin", value = "false" },
        { name = "BKSB__APP__AssessmentFinishedNotificationURL", value = "https://bksb.stage.euw2.bksb.dev/bksblive2/SendV5.aspx" },
        { name = "BKSB__APP__AssessmentResultFileStoreRegion", value = "eu-west-1" },
        { name = "BKSB__APP__AssessmentResultRootPartition", value = "bksbdevenginecontent-stage" },
        { name = "BKSB__APP__AssessmentResultRootPath", value = "aus/assessment-engine/assessment-results-live/" },
        { name = "BKSB__APP__CourseFileStoreRegion", value = "eu-west-1" },
        { name = "BKSB__APP__CourseFlowsFileStoreRegion", value = "eu-west-1" },
        { name = "BKSB__APP__CourseFlowsRootPartition", value = "bksbdevenginecontent-stage" },
        { name = "BKSB__APP__CourseFlowsRootPath", value = "aus/course-flows" },
        { name = "BKSB__APP__CourseRootPartition", value = "bksbdevenginecontent-stage" },
        { name = "BKSB__APP__CourseRootPath", value = "aus/courses/courses" },
        { name = "BKSB__APP__HostingBasePath", value = "/bksblive2/v5api/" },
        { name = "BKSB__APP__KeyFileStoreRegion", value = "eu-west-2" },
        { name = "BKSB__APP__KeyRootPartition", value = "staging-bksb-fargate-ireland-key" },
        { name = "BKSB__APP__KeyRootPath", value = "aus/applicationkeys/signing-keys" },
        { name = "BKSB__APP__NotifyWhenAssessmentFinished", value = "true" },
        { name = "BKSB__APP__ProgressFileStoreRegion", value = "eu-west-1" },
        { name = "BKSB__APP__ProgressRootPartition", value = "bksbdevenginecontent-stage" },
        { name = "BKSB__APP__ProgressRootPath", value = "aus/resource-engine/progress-live/" },
        { name = "BKSB__APP__QuestionFileStoreRegion", value = "eu-west-1" },
        { name = "BKSB__APP__QuestionRootPartition", value = "bksbdevenginecontent-stage" },
        { name = "BKSB__APP__QuestionRootPath", value = "aus/assessment-engine/questions/" },
        { name = "BKSB__APP__ResourceFileStoreRegion", value = "eu-west-1" },
        { name = "BKSB__APP__ResourceRootPartition", value = "bksbbuildercontentdev" },
        { name = "BKSB__APP__ResourceRootPath", value = "aus/builderv5/resources_dev" },
        { name = "BKSB__APP__ResponseFileStoreRegion", value = "eu-west-1" },
        { name = "BKSB__APP__ResponseRootPartition", value = "bksbdevenginecontent-stage" },
        { name = "BKSB__APP__ResponseRootPath", value = "aus/assessment-engine/responses-live/" },
        { name = "BKSB__APP__TransferTokenSigningKeyFileStoreRegion", value = "eu-west-2" },
        { name = "BKSB__APP__TransferTokenSigningKeyPath", value = "transfer.txt" },
        { name = "BKSB__APP__TransferTokenSigningKeyRootPartition", value = "staging-bksb-fargate-ireland-key" },
        { name = "BKSB__APP__TransferTokenSigningKeyRootPath", value = "domainkeys/staging.euw2.bksb.dev/" },
        { name = "BKSB__APP__UseLocalFileStores", value = "false" },
        { name = "BKSB__APP__ValidTransferTokenAudience", value = "bksblive2.co.uk" },
        { name = "BKSB__APP__ValidTransferTokenIssuer", value = "stage.euw2.bksb.dev" },
        { name = "ComPlus_ThreadPool_ForceMinWorkerThreads", value = "32" },
        { name = "COMPlus_ThreadPool_ForceMinWorkerThreads", value = "32" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.bksb_reforms_api_ecs_container_log_group.name
          "awslogs-stream-prefix" = "bksb-ecs"
          "awslogs-region"        = "ap-southeast-2"
        }
      }
      secrets = [
        { name = "BKSB__DB__DatabaseConnectionString", valueFrom = var.db_connection_string_secret_arn },
        { name = "BKSB__APP__SessionStoreConfigString", valueFrom = var.redis_connection_string_secret_arn },
        { name = "BKSB__APP__TransferTokenInvalidationStoreConfigString", valueFrom = var.redis_connection_string_secret_arn }
      ]
    },
    {
      name        = "xray-daemon"
      cpu         = 32
      memoryReservation = 256
      essential   = true
      image       = "amazon/aws-xray-daemon:latest"
      portMappings = [
        {
          containerPort = 2000
          protocol      = "udp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.bksb_reforms_api_xray_ecs_container_log_group.name
          "awslogs-stream-prefix" = "bksb-ecs"
          "awslogs-region"        = "ap-southeast-2"
        }
      }
    }
  ])

  tags = {
    "Name" = "StageBKSBReformsAPIAppSydney/BKSBReformsAPIECSContainerTaskDefinition/Resource"
  }
}

# AWS::ECS::Service
resource "aws_ecs_service" "bksb_reforms_api_ecs_service" {
  name                            = "bksb-reforms-api-service"
  cluster                         = var.cluster_name
  task_definition                 = aws_ecs_task_definition.bksb_reforms_api_task_definition.arn
  desired_count                   = 3
  launch_type                     = "FARGATE"
  enable_ecs_managed_tags         = false
  enable_execute_command          = false
  health_check_grace_period_seconds = 60
  deployment_controller {
    type = "CODE_DEPLOY"
  }
  deployment_maximum_percent        = 200
  deployment_minimum_healthy_percent = 50

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target_group_one.arn
    container_name   = "bksb-reforms-api"
    container_port   = 443
  }

  network_configuration {
    subnets          = [var.subnet_1_id, var.subnet_2_id]
    security_groups  = [aws_security_group.bksb_reforms_api_sg.id]
    assign_public_ip = false
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    "Name" = "StageBKSBReformsAPIAppSydney/BKSBReformsAPIECSService/Service"
  }
}

# AWS::ApplicationAutoScaling::ScalableTarget
resource "aws_appautoscaling_target" "ecs_scalable_target" {
  max_capacity       = 12
  min_capacity       = 3
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.bksb_reforms_api_ecs_service.name}"
  role_arn           = "arn:aws:iam::352515133004:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [
    aws_ecs_service.bksb_reforms_api_ecs_service
  ]
}

# AWS::ApplicationAutoScaling::ScalingPolicy
resource "aws_appautoscaling_policy" "ecs_scaling_policy" {
  name               = "BKSBReformsAPIECSServiceTaskCountTargetBKSBReformsAPIECSServiceScaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_scalable_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_scalable_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_scalable_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 50
  }

  depends_on = [
    aws_appautoscaling_target.ecs_scalable_target
  ]
}

# AWS::CodeDeploy::Application
resource "aws_codedeploy_app" "code_deploy_application" {
  name             = "StageBKSBReformsAPIAppSydney"
  compute_platform = "ECS"

  tags = {
    "Name" = "StageBKSBReformsAPIAppSydeny/CDApplication/Resource"
  }
}

# AWS::IAM::Role - CDRole
resource "aws_iam_role" "codedeploy_role" {
  name = "CodeDeployRoleForECS"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      },
    ]
  })
  # The 'managed_policy_arns' argument has been removed as it's deprecated.
  # The policy attachment will be handled by a separate 'aws_iam_role_policy_attachment' resource.

  tags = {
    "Name" = "StageBKSBReformsAPIAppSydney/CDRole/Resource"
  }
}

# Add a separate resource to attach the managed policy
resource "aws_iam_role_policy_attachment" "codedeploy_role_managed_policy_attachment" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# AWS::CodeDeploy::DeploymentGroup
resource "aws_codedeploy_deployment_group" "code_deploy_deployment_group" {
  app_name                = aws_codedeploy_app.code_deploy_application.name
  deployment_group_name   = "StageBKSBReformsAPIAppSydneyDeploymentGroup"
  service_role_arn        = aws_iam_role.codedeploy_role.arn
  deployment_config_name  = "CodeDeployDefault.ECSAllAtOnce"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_REQUEST"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 1440
    }
    terminate_blue_instances_on_deployment_success {
      action                       = "TERMINATE"
      termination_wait_time_in_minutes = 60
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.cluster_name
    service_name = aws_ecs_service.bksb_reforms_api_ecs_service.name
  }

load_balancer_info {
  target_group_pair_info {
    prod_traffic_route {
      listener_arns = [var.alb_listener_prod_arn]
    }

    test_traffic_route {
      listener_arns = [var.alb_listener_test_arn]
    }

    target_group {
      name = aws_lb_target_group.alb_target_group_one.name
    }

    target_group {
      name = aws_lb_target_group.alb_target_group_two.name
    }
  }
}
}