resource "aws_security_group_rule" "ALBProdListenerSecurityGroupEgress" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  description              = "Load balancer to target"
  security_group_id        = var.new_alb_security_group_id  # Updated variable reference
  source_security_group_id = aws_security_group.BKSBReformsClientSG.id  # Updated reference
}

resource "aws_lb_target_group" "ALBTargetGroupOne" {
  name     = "NewALBTargetGroupOne"  # Updated name
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
    type    = "lb_cookie"
  }
}

resource "aws_lb_target_group" "ALBTargetGroupTwo" {
  name     = "NewALBTargetGroupTwo"  # Updated name
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
    type    = "lb_cookie"
  }
}

resource "aws_lb_listener_rule" "ALBProdListenerRule" {
  listener_arn = var.prod_listener_arn  # Updated variable reference
  priority     = 4

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ALBTargetGroupOne.arn  # Updated reference
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
  listener_arn = var.test_listener_arn  # Updated variable reference
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
    target_group_arn = aws_lb_target_group.ALBTargetGroupTwo.arn  # Updated reference
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
  name        = "NewBKSBReformsClientSG"  # Updated name
  description = "NewProdBKSBReformsWebClientAppLondon/NewBKSBReformsClientSG"  # Updated description
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
  type                    = "ingress"
  security_group_id      = aws_security_group.BKSBReformsClientSG.id  # Updated reference
  protocol                = "tcp"
  from_port              = 443
  to_port                = 443
  description             = "Load balancer to target"
  source_security_group_id = var.new_alb_security_group_id  # Updated variable reference
}

resource "aws_iam_role" "BKSBReformsClientECSContainerTaskDefinitionTaskRole" {
  name = "NewBKSBReformsClientECSContainerTaskDefinitionTaskRole"  # Updated name

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
  name = "NewBKSBReformsClientECSContainerTaskDefinitionTaskRoleDefaultPolicy"  # Updated name
  role = aws_iam_role.BKSBReformsClientECSContainerTaskDefinitionTaskRole.name  # Updated reference

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
          "arn:aws:s3:::newcdn.private.bksb.co.uk",  # Updated resource
          "arn:aws:s3:::newcdn.private.bksb.co.uk/*"  # Updated resource
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
        Resource = "*"  # No change
      }
    ]
  })
}

resource "aws_ecs_task_definition" "BKSBReformsClientECSContainerTaskDefinition" {
  family                   = "new_prod_bksb-reforms-web-client"  # Updated family name
  network_mode             = "awsvpc"
  requires_compatibilities  = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.BKSBReformsClientECSContainerTaskDefinitionExecutionRole.arn
  task_role_arn            = aws_iam_role.BKSBReformsClientECSContainerTaskDefinitionTaskRole.arn  # Updated reference

  container_definitions = jsonencode([
    {
      name      = "new_bksb-reforms-web-client"  # Updated container name
      image     = "592311462240.dkr.ecr.eu-west-2.amazonaws.com/bksb/dev/new_bksb-reforms-web-clients:128-linux-x86_64"  # Updated image
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
          value = "new_bksblive2.co.uk/bksblive2/Login.aspx"  # Updated value
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
          value = "newcdn.private.bksb.co.uk"  # Updated value
        },
        {
          name  = "BKSB__APP__FSRootPath"
          value = "new_ecl/0.3.4/"  # Updated value
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
  name            = "NewBKSBReformsClientECSService"  # Updated name
  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.BKSBReformsClientECSContainerTaskDefinition.arn  # Updated reference
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = "DISABLED"
    security_groups  = [aws_security_group.BKSBReformsClientSG.id]  # Updated reference
    subnets          = var.subnet_ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ALBTargetGroupOne.arn  # Updated reference
    container_name   = "new_bksb-reforms-web-client"  # Updated container name
    container_port   = 443
  }
}

resource "aws_application_autoscaling_target" "BKSBReformsClientECSServiceTaskCountTarget" {
  max_capacity       = 12
  min_capacity       = 1
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.BKSBReformsClientECSService.name}"  # Updated reference
  scalable_dimension  = "ecs:service:DesiredCount"
  service_namespace   = "ecs"
}

resource "aws_application_autoscaling_policy" "BKSBReformsClientECSServiceScalingPolicy" {
  name                   = "NewBKSBReformsClientECSServiceScalingPolicy"  # Updated name
  policy_type           = "TargetTrackingScaling"
  scaling_target_id     = aws_application_autoscaling_target.BKSBReformsClientECSServiceTaskCountTarget.id  # Updated reference

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 50
  }
}

resource "aws_codedeploy_app" "CDApplication" {
  name             = "NewCDApplication"  # Updated name
  compute_platform = "ECS"
}

resource "aws_iam_role" "CDRole" {
  name = "NewCDRole"  # Updated name

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
  name = "NewAWSCodeDeployRoleForECS"  # Updated name
  role = aws_iam_role.CDRole.name  # Updated reference

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
        Resource = "*"  # No change
      }
    ]
  })
}

resource "aws_codedeploy_deployment_group" "CDDeploymentGroup" {
  app_name               = aws_codedeploy_app.CDApplication.name
  deployment_group_name  = "NewBKSBReformsClientECSDeploymentGroup"  # Updated name
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
    service_name = aws_ecs_service.BKSBReformsClientECSService.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.prod_listener_arn]  # Updated variable reference
      }

      test_traffic_route {
        listener_arns = [var.test_listener_arn]  # Updated variable reference
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