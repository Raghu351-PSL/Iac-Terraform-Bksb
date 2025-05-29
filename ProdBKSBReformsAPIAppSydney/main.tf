resource "aws_security_group_rule" "AllowFromALBToAPISG" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  description              = "Allow traffic from ALB SG to API SG"
  security_group_id        = aws_security_group.BKSBReformsAPISG.id
  source_security_group_id = var.alb_security_group_id
}

resource "aws_lb_target_group" "ALBTargetGroupOne" {
  name     = "ALBTargetGroupOne"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/api/healthCheck"
    interval            = 20
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 4
  }

  stickiness {
    enabled = false
    type = "lb_cookie"
  }
}

resource "aws_lb_target_group" "ALBTargetGroupTwo" {
  name     = "ALBTargetGroupTwo"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/api/healthCheck"
    interval            = 20
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 4
  }

  stickiness {
    enabled = false
    type = "lb_cookie"
  }
}

resource "aws_lb_listener_rule" "ALBProdListenerRule" {
  listener_arn = var.prod_listener_arn
  priority     = 3

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ALBTargetGroupOne.arn
  }

  condition {
    path_pattern {
      values = ["/bksblive2/v5api/*"]
    }
  }

  condition {
    http_header {
      http_header_name = "x-bksb-internal"
      values           = ["{{resolve:secretsmanager:arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/loadbalancer/load_balancer_secret:SecretString:::}}"]
    }
  }
}

resource "aws_lb_listener_rule" "ALBTestListenerRule" {
  listener_arn = var.test_listener_arn
  priority     = 104

  action {
    type = "authenticate-oidc"
    order = 1
    authenticate_oidc {
      authorization_endpoint = "https://identity.oneadvanced.com/auth/realms/education-platform/protocol/openid-connect/auth"
      client_id              = "education-preprod-alb"
      client_secret          = "{{resolve:secretsmanager:arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/loadbalancer/alb_authentication_secret:SecretString:::}}"
      issuer                 = "https://identity.oneadvanced.com/auth/realms/education-platform"
      scope                  = "openid"
      token_endpoint         = "https://identity.oneadvanced.com/auth/realms/education-platform/protocol/openid-connect/token"
      user_info_endpoint     = "https://identity.oneadvanced.com/auth/realms/education-platform/protocol/openid-connect/userinfo"
    }
  }

  action {
    type             = "forward"
    order            = 2
    target_group_arn = aws_lb_target_group.ALBTargetGroupTwo.arn
  }

  condition {
    path_pattern {
      values = ["/bksblive2/v5api/*"]
    }
  }

  condition {
    http_header {
      http_header_name = "x-bksb-internal"
      values           = ["{{resolve:secretsmanager:arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/loadbalancer/load_balancer_secret:SecretString:::}}"]
    }
  }
}

resource "aws_security_group" "BKSBReformsAPISG" {
  name        = "BKSBReformsAPISG"
  description = "ProdBKSBReformsAPIAppLondon/BKSBReformsAPISG"
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
}

resource "aws_security_group_rule" "BKSBReformsAPISGIngress" {
  type                    = "ingress"
  security_group_id      = aws_security_group.BKSBReformsAPISG.id
  protocol                = "tcp"
  from_port              = 443
  to_port                = 443
  description             = "Load balancer to target"
  source_security_group_id = var.alb_security_group_id
}

resource "aws_iam_role" "BKSBReformsAPIECSContainerTaskDefinitionTaskRole" {
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
      }
    ]
  })
}

resource "aws_iam_role_policy" "BKSBReformsAPIDefaultPolicy" {
  name = "BKSBReformsAPIECSContainerTaskDefinitionTaskRoleDefaultPolicy"
  role = aws_iam_role.BKSBReformsAPIECSContainerTaskDefinitionTaskRole.name

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
          "arn:aws:s3:::bksb-fargate-ireland-key",
          "arn:aws:s3:::bksb-fargate-ireland-key/*",
          "arn:aws:s3:::bksbdevenginecontent",
          "arn:aws:s3:::bksbdevenginecontent/*"
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
      }
    ]
  })
}

resource "aws_ecs_task_definition" "BKSBReformsAPIECSContainerTaskDefinition" {
  family                   = "prod_bksb-reforms-api"
  network_mode             = "awsvpc"
  requires_compatibilities  = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "8192"
  execution_role_arn       = aws_iam_role.BKSBReformsAPIECSContainerTaskDefinitionExecutionRoleC05553F4.arn
  task_role_arn            = aws_iam_role.BKSBReformsAPIECSContainerTaskDefinitionTaskRole.arn

  container_definitions = jsonencode([
    {
      name      = "bksb-reforms-api"
      image     = "592311462240.dkr.ecr.eu-west-2.amazonaws.com/bksb/dev/bksb-reforms-service:98-linux-x86_64"
      cpu       = 2016
      memory    = 7936
      essential = true
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
          name  = "BKSB__APP__DeferLogin"
          value = "true"
        },
        {
          name  = "BKSB__APP__DeferredLoginTransferPagePath"
          value = "/bksblive2/V5Transition.aspx"
        },
        {
          name  = "BKSB__APP__DeferredLoginURL"
          value = "bksblive2.co.uk/bksblive2/Login.aspx"
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
          value = "eu-west-1"
        },
        {
          name  = "BKSB__APP__FSRootPartition"
          value = "cdn.private.bksb.co.uk"
        },
        {
          name  = "BKSB__APP__FSRootPath"
          value = "ecl/0.3.4/"
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
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.BKSBReformsAPIECSContainerTaskDefinitionBKSBReformsAPIECSContainerLogGroup41749BF1.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix  = "bksb-ecs"
        }
      }
      secrets = [
        {
          name      = "BKSB__DB__DatabaseConnectionString"
          valueFrom = "arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/bksb-reforms-api/db_connection_string"
        },
        {
          name      = "BKSB__APP__SessionStoreConfigString"
          valueFrom = "arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/bksb-reforms-api/redis_connection_string"
        },
        {
          name      = "BKSB__APP__TransferTokenInvalidationStoreConfigString"
          valueFrom = "arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/bksb-reforms-api/redis_connection_string"
        }
      ]
    },
    {
      name      = "xray-daemon"
      image     = "amazon/aws-xray-daemon:latest"
      cpu       = 32
      memoryReservation = 256
      essential = true
      portMappings = [
        {
          containerPort = 2000
          protocol      = "udp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.BKSBReformsAPIECSContainerTaskDefinitionBKSBLive2ReformsAPIXRayECSContainerLogGroupCD8A9FA5.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix  = "bksb-ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "BKSBReformsAPIECSContainerTaskDefinitionBKSBReformsAPIECSContainerLogGroup" {
  name              = "BKSBReformsAPIECSContainerTaskDefinitionBKSBReformsAPIECSContainerLogGroup"
  retention_in_days = 7
}

resource "aws_ecs_service" "BKSBReformsAPIECSService" {
  name            = "BKSBReformsAPIECSService"
  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.BKSBReformsAPIECSContainerTaskDefinition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = "DISABLED"
    security_groups  = [aws_security_group.BKSBReformsAPISG.id]
    subnets          = var.subnet_ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ALBTargetGroupOne.arn
    container_name   = "bksb-reforms-api"
    container_port   = 443
  }
}

resource "aws_application_autoscaling_target" "BKSBReformsAPIECSServiceTaskCountTarget" {
  max_capacity       = 12
  min_capacity       = 3
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.BKSBReformsAPIECSService.name}"
  scalable_dimension  = "ecs:service:DesiredCount"
  service_namespace   = "ecs"
}

resource "aws_application_autoscaling_policy" "BKSBReformsAPIECSServiceScalingPolicy" {
  name                   = "BKSBReformsAPIECSServiceScalingPolicy"
  policy_type           = "TargetTrackingScaling"
  scaling_target_id     = aws_application_autoscaling_target.BKSBReformsAPIECSServiceTaskCountTarget.id

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 50
  }
}

resource "aws_codedeploy_app" "CDApplication" {
  name             = "CDApplication"
  compute_platform = "ECS"
}

resource "aws_iam_role" "CDRole" {
  name = "CDRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.eu-west-2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "CDRolePolicy" {
  name = "AWSCodeDeployRoleForECS"
  role = aws_iam_role.CDRole.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "codedeploy:*",
          "ecs:*",
          "elasticloadbalancing:*",
          "iam:PassRole"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_codedeploy_deployment_group" "CDDeploymentGroup" {
  app_name               = aws_codedeploy_app.CDApplication.name
  deployment_group_name  = "BKSBReformsAPIECSDeploymentGroup"
  service_role_arn       = aws_iam_role.CDRole.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_REQUEST"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout     = "STOP_DEPLOYMENT"
      wait_time_in_minutes  = 1440
    }

    terminate_blue_instances_on_deployment_success {
      action                         = "TERMINATE"
      termination_wait_time_in_minutes = 60
    }
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = aws_ecs_service.BKSBReformsAPIECSService.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.prod_listener_arn]
      }

      test_traffic_route {
        listener_arns = [var.test_listener_arn]
      }

      target_group {
        name = aws_lb_target_group.ALBTargetGroupOne.name
      }

      target_group {
        name = aws_lb_target_group.ALBTargetGroupTwo.name
      }
    }
  }
}