# Data source for Load Balancer Secret
data "aws_secretsmanager_secret_version" "load_balancer_secret" {
  secret_id = var.load_balancer_secret_arn
}

# ALB Listener Security Group Egress
resource "aws_security_group_rule" "alb_prod_listener_egress_to_client_sg" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bksb_reforms_client_sg.id
  security_group_id        = var.alb_prod_listener_sg_id
  description              = "Load balancer to target"
}

# ALB Target Group One
resource "aws_lb_target_group" "alb_target_group_one" {
  name        = "ALBTargetGroupOnewebclient"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    enabled             = true
    interval            = 20
    path                = "/healthCheck"
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 4
  }
  tags = {
    Name = "ALBTargetGroupwebclientOne"
  }
}

# ALB Target Group Two
resource "aws_lb_target_group" "alb_target_group_two" {
  name        = "ALBTargetGroupTwowebclient"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    enabled             = true
    interval            = 20
    path                = "/healthCheck"
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 4
  }
  tags = {
    Name = "ALBTargetGroupwebclientTwo"
  }
}

resource "aws_lb_listener_rule" "alb_listener_rule" {
  listener_arn = var.alb_prod_listener_arn
  priority     = 110 # Changed to a unique value

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group_one.arn
  }

  condition {
    path_pattern {
      values = ["/bksblive2/v5api/*"]
    }
  }

  depends_on = [
    aws_lb_target_group.alb_target_group_one
  ]
}

# BKSB Reforms Client Security Group
resource "aws_security_group" "bksb_reforms_client_sg" {
  name        = "StageBKSBReformsWebClientAppSydney-BKSBReformsClientSG"
  description = "StageBKSBReformsWebClientAppSydney/BKSBReformsClientSG"
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

  tags = {
    Name = "StageBKSBReformsWebClientAppSydney-BKSBReformsClientSG"
  }
}

# BKSB Reforms Client Security Group Ingress from ALB Listener SG
resource "aws_security_group_rule" "bksb_reforms_client_sg_ingress_from_alb" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = var.alb_prod_listener_sg_id
  security_group_id        = aws_security_group.bksb_reforms_client_sg.id
  description              = "Load balancer to target"
}

# ECS Task Role for BKSB Reforms Client Container
resource "aws_iam_role" "bksb_reforms_client_ecs_task_role" {
  name = "Stage-BKSBReformsClientECSContainerTaskRole"
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
}

# ECS Task Role Default Policy
resource "aws_iam_policy" "bksb_reforms_client_ecs_task_role_policy" {
  name = "StageBKSBReformsWebClientAppSydney-BKSBReformsClientECSContainerTaskRoleDefaultPolicy"
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
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.s3_cdn_private_bucket_name}",
          "arn:aws:s3:::${var.s3_cdn_private_bucket_name}/*"
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
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bksb_reforms_client_ecs_task_role_policy_attachment" {
  role       = aws_iam_role.bksb_reforms_client_ecs_task_role.name
  policy_arn = aws_iam_policy.bksb_reforms_client_ecs_task_role_policy.arn
}

# ECS Execution Role
resource "aws_iam_role" "bksb_reforms_client_ecs_execution_role" {
  name = "Stage-BKSBReformsClientECSContainerTaskDefinitionExecutionRole"
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
    Name = "StageBKSBReformsWebClientAppSydney"
  }
}

# ECS Execution Role Default Policy
resource "aws_iam_policy" "bksb_reforms_client_ecs_execution_role_policy" {
  name = "StageBKSBReformsWebClientAppSydney-BKSBReformsClientECSContainerTaskDefinitionExecutionRoleDefaultPolicy"
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
        Effect = "Allow"
        Resource = "arn:aws:ecr:eu-west-2:592311462240:repository/bksb/dev/bksblive2-reforms-web-clients"
      },
      {
        Action = "ecr:GetAuthorizationToken"
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_cloudwatch_log_group.bksb_reforms_client_xray_log_group.arn}:*",
          "${aws_cloudwatch_log_group.bksb_reforms_client_container_log_group.arn}:*"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bksb_reforms_client_ecs_execution_role_policy_attachment" {
  role       = aws_iam_role.bksb_reforms_client_ecs_execution_role.name
  policy_arn = aws_iam_policy.bksb_reforms_client_ecs_execution_role_policy.arn
}

# BKSB Reforms Client ECS Container Log Group
resource "aws_cloudwatch_log_group" "bksb_reforms_client_container_log_group" {
  name              = "/ecs/StageBKSBReformsWebClientAppSydney/BKSBReformsClientECSContainer"
  retention_in_days = 7
  tags = {
    Name = "bksb-reforms-web-client-log-group"
  }
}

# BKSB Reforms Client XRay ECS Container Log Group
resource "aws_cloudwatch_log_group" "bksb_reforms_client_xray_log_group" {
  name              = "/ecs/StageBKSBReformsWebClientAppSydney/BKSBLive2ReformsAPIXRayECSContainer"
  retention_in_days = 7
  tags = {
    Name = "bksb-reforms-xray-log-group"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "bksb_reforms_client_task_definition" {
  family                   = "stage_bksb-reforms-web-client"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.bksb_reforms_client_ecs_execution_role.arn
  task_role_arn            = aws_iam_role.bksb_reforms_client_ecs_task_role.arn
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name        = "bksb-reforms-web-client"
      image       = var.web_client_image
      cpu         = 224
      memory      = 256
      essential   = true
      portMappings = [
        {
          containerPort = 443
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = "Production"
        },
        {
          name  = "ASPNETCORE_URLS"
          value = "https://+:443"
        },
        {
          name  = "BKSB__App__DeferLogin"
          value = "true"
        },
        {
          name  = "BKSB__App__DeferredLoginTransferPagePath"
          value = "/bksblive2/V5Transition.aspx"
        },
        {
          name  = "BKSB__App__DeferredLoginURL"
          value = "stage.euw2.bksb.dev/bksblive2/Login.aspx"
        },
        {
          name  = "BKSB__APP__DisplayNavbar"
          value = "false"
        },
        {
          name  = "BKSB__APP__DisplaySidebar"
          value = "false"
        },
        {
          name  = "BKSB__APP__FSRegion"
          value = "ap-southeast-2"
        },
        {
          name  = "BKSB__APP__FSRootPartition"
          value = var.s3_cdn_private_bucket_name
        },
        {
          name  = "BKSB__APP__FSRootPath"
          value = "ecl/0.3.7/"
        },
        {
          name  = "BKSB__APP__FSUseLocal"
          value = "false"
        },
        {
          name  = "BKSB__APP__HostingBasePath"
          value = "/bksblive2/v5/"
        },
        {
          name  = "BKSB__APP__V5APIRootURL"
          value = "/bksblive2/v5api/api"
        },
        {
          name  = "BKSB__APP__CEHostPath"
          value = "https://myworkplace.oneadvanced.io"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.bksb_reforms_client_container_log_group.name
          "awslogs-stream-prefix" = "bksb-ecs"
          "awslogs-region"        = "ap-southeast-2"
        }
      }
    },
    {
      name        = "xray-daemon"
      image       = var.xray_daemon_image
      cpu         = 32
      memoryReservation = 256
      essential   = true
      portMappings = [
        {
          containerPort = 2000
          protocol      = "udp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.bksb_reforms_client_xray_log_group.name
          "awslogs-stream-prefix" = "bksb-ecs"
          "awslogs-region"        = "ap-southeast-2"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "bksb_reforms_client_ecs_service" {
  name                              = "StageBKSBReformsWebClientAppSydney-BKSBReformsClientECSService"
  cluster                           = var.ecs_cluster_name
  task_definition                   = aws_ecs_task_definition.bksb_reforms_client_task_definition.arn
  launch_type                       = "FARGATE"
  enable_ecs_managed_tags           = false
  enable_execute_command            = false
  health_check_grace_period_seconds = 60
  deployment_controller {
    type = "CODE_DEPLOY"
  }
  # deployment_circuit_breaker {
  #   enable   = true
  #   rollback = true
  # }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target_group_one.arn
    container_name   = "bksb-reforms-web-client"
    container_port   = 443
  }

  network_configuration {
    subnets          = [var.subnet_1_id, var.subnet_2_id]
    security_groups  = [aws_security_group.bksb_reforms_client_sg.id]
    assign_public_ip = false
  }

  desired_count = 1

  depends_on = [
    aws_lb_listener_rule.alb_listener_rule
  ]
}

# Auto Scaling Scalable Target
resource "aws_appautoscaling_target" "bksb_reforms_client_ecs_scalable_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.bksb_reforms_client_ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 12
  role_arn           = "arn:aws:iam::352515133004:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService"
}

# Auto Scaling Scaling Policy
resource "aws_appautoscaling_policy" "bksb_reforms_client_ecs_scaling_policy" {
  name               = "StageBKSBReformsWebClientECSServiceTaskCountTargetBKSBReformsClientECSServiceScaling"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.bksb_reforms_client_ecs_scalable_target.resource_id
  scalable_dimension = "ecs:service:DesiredCount"
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 50
  }
}

# CodeDeploy Application
resource "aws_codedeploy_app" "code_deploy_application" {
  name             = "StageBKSBReformsWebClientAppSydney-CDApplication"
  compute_platform = "ECS"
}

# CodeDeploy Role
resource "aws_iam_role" "code_deploy_role" {
  name = "StageBKSBReformsWebClientAppSydney-CDRole"
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
}

resource "aws_iam_policy_attachment" "codedeploy_ecs_policy_attachment" {
  name = "codedeploy-ecs-policy-attachment"
  roles = [
    aws_iam_role.code_deploy_role.name
  ]
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "code_deploy_deployment_group" {
  app_name               = aws_codedeploy_app.code_deploy_application.name
  deployment_group_name  = "StageBKSBReformsWebClientAppSydney-CDDeploymentGroup"
  service_role_arn       = aws_iam_role.code_deploy_role.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

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
      action                        = "TERMINATE"
      termination_wait_time_in_minutes = 60
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = aws_ecs_service.bksb_reforms_client_ecs_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.alb_prod_listener_arn]
      }

      target_group {
        name = aws_lb_target_group.alb_target_group_one.name
      }

      target_group {
        name = aws_lb_target_group.alb_target_group_two.name
      }

      test_traffic_route {
        listener_arns = [var.alb_test_listener_arn]
      }
    }
  }
}