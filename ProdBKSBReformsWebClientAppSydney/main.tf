resource "aws_security_group_rule" "ALBProdListenerSecurityGroupEgress" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  description              = "Load balancer to target"
  security_group_id        = var.alb_security_group_id
  source_security_group_id = aws_security_group.BKSBReformsClientSG0E65BB13.id
}

resource "aws_lb_target_group" "ALBTargetGroupOne" {
  name     = "ALBTargetGroupOne"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/healthCheck"
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
    path                = "/healthCheck"
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
  priority     = 4

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ALBTargetGroupOne.arn
  }

  condition {
    path_pattern {
      values = ["/bksblive2/v5/*"]
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
    authenticate_oidc {
      authorization_endpoint = "https://identity.oneadvanced.com/auth/realms/education-platform/protocol/openid-connect/auth"
      client_id              = "education-preprod-alb"
      client_secret          = "{{resolve:secretsmanager:arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/loadbalancer/alb_authentication_secret:SecretString:::}}"
      issuer                 = "https://identity.oneadvanced.com/auth/realms/education-platform"
      scope                  = "openid"
      token_endpoint         = "https://identity.oneadvanced.com/auth/realms/education-platform/protocol/openid-connect/token"
      user_info_endpoint     = "https://identity.oneadvanced.com/auth/realms/education-platform/protocol/openid-connect/userinfo"
    }
    order = 1
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ALBTargetGroupTwo.arn
    order            = 2
  }

  condition {
    path_pattern {
      values = ["/bksblive2/v5/*"]
    }
  }

  condition {
    http_header {
      http_header_name = "x-bksb-internal"
      values           = ["{{resolve:secretsmanager:arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/loadbalancer/load_balancer_secret:SecretString:::}}"]
    }
  }
}

resource "aws_security_group" "BKSBReformsClientSG" {
  name        = "BKSBReformsClientSG"
  description = "ProdBKSBReformsWebClientAppLondon/BKSBReformsClientSG"
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
}

resource "aws_security_group_rule" "BKSBReformsClientSGIngress" {
  type              = "ingress"
  security_group_id = aws_security_group.BKSBReformsClientSG.id
  protocol          = "tcp"
  from_port        = 443
  to_port          = 443
  description       = "Load balancer to target"
  source_security_group_id = var.alb_security_group_id
}

resource "aws_iam_role" "BKSBReformsClientECSContainerTaskDefinitionTaskRole" {
  name = "BKSBReformsClientECSContainerTaskDefinitionTaskRole"

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
resource "aws_iam_role_policy" "BKSBReformsClientECSContainerTaskDefinitionTaskRoleDefaultPolicy" {
  name = "BKSBReformsClientECSContainerTaskDefinitionTaskRoleDefaultPolicy"
  role = aws_iam_role.BKSBReformsClientECSContainerTaskDefinitionTaskRole.name

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
          "arn:aws:s3:::cdn.private.bksb.co.uk",
          "arn:aws:s3:::cdn.private.bksb.co.uk/*"
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

resource "aws_ecs_task_definition" "BKSBReformsClientECSContainerTaskDefinition" {
  family                   = "prod_bksb-reforms-web-client"
  network_mode             = "awsvpc"
  requires_compatibilities  = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.BKSBReformsClientECSContainerTaskDefinitionExecutionRole.arn
  task_role_arn            = aws_iam_role.BKSBReformsClientECSContainerTaskDefinitionTaskRole.arn

  container_definitions = jsonencode([
    {
      name      = "bksb-reforms-web-client"
      image     = "592311462240.dkr.ecr.eu-west-2.amazonaws.com/bksb/dev/bksblive2-reforms-web-clients:128-linux-x86_64"
      cpu       = 224
      memory    = 256
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
          name  = "BKSB__App__DeferLogin"
          value = "true"
        },
        {
          name  = "BKSB__App__DeferredLoginTransferPagePath"
          value = "/bksblive2/V5Transition.aspx"
        },
        {
          name  = "BKSB__App__DeferredLoginURL"
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
          awslogs-group         = aws_cloudwatch_log_group.BKSBReformsClientECSContainerLogGroup.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix  = "bksb-ecs"
        }
      }
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
          awslogs-group         = aws_cloudwatch_log_group.BKSBReformsClientECSContainerTaskDefinitionBKSBLive2ReformsAPIXRayECSContainerLogGroup.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix  = "bksb-ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "BKSBReformsClientECSContainerLogGroup" {
  name              = "BKSBReformsClientECSContainerLogGroup"
  retention_in_days = 7
}

resource "aws_ecs_service" "BKSBReformsClientECSService" {
  name            = "BKSBReformsClientECSService"
  cluster         = aws_ecs_cluster.BKSBReformsECSCluster.id
  task_definition = aws_ecs_task_definition.BKSBReformsClientECSContainerTaskDefinition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = "DISABLED"
    security_groups  = [aws_security_group.BKSBReformsClientSG.id]
    subnets          = [
      aws_subnet.Live2ClusterSubnet1.id,
      aws_subnet.Live2ClusterSubnet2.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ALBTargetGroupOne.arn
    container_name   = "bksb-reforms-web-client"
    container_port   = 443
  }
}

resource "aws_application_autoscaling_target" "BKSBReformsClientECSServiceTaskCountTarget" {
  max_capacity       = 12
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.BKSBReformsECSCluster.name}/${aws_ecs_service.BKSBReformsClientECSService.name}"
  scalable_dimension  = "ecs:service:DesiredCount"
  service_namespace   = "ecs"
}

resource "aws_application_autoscaling_policy" "BKSBReformsClientECSServiceScalingPolicy" {
  name                   = "BKSBReformsClientECSServiceScalingPolicy"
  policy_type           = "TargetTrackingScaling"
  scaling_target_id     = aws_application_autoscaling_target.BKSBReformsClientECSServiceTaskCountTarget.id

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

resource "aws_iam_role_policy_attachment" "CDRoleAttachment" {
  role       = aws_iam_role.CDRole.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

resource "aws_codedeploy_deployment_group" "CDDeploymentGroup" {
  app_name              = aws_codedeploy_app.CDApplication.name
  deployment_group_name = "CDDeploymentGroup"
  service_role_arn      = aws_iam_role.CDRole.arn
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
    cluster_name = aws_ecs_cluster.BKSBReformsECSCluster.name
    service_name = aws_ecs_service.BKSBReformsClientECSService.name
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
