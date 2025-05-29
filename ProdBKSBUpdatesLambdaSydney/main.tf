resource "aws_iam_role" "bksbUpdatesLambdaServiceRole" {
  name = "bksbUpdatesLambdaServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "bksbUpdatesLambdaServicePolicy" {
  name = "bksbUpdatesLambdaServiceRoleDefaultPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetBucket*",
          "s3:GetObject*",
          "s3:List*"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::bksb-prod-updates-eu-west-2",
          "arn:aws:s3:::bksb-prod-updates-eu-west-2/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bksbUpdatesLambdaServicePolicyAttachment" {
  role       = aws_iam_role.bksbUpdatesLambdaServiceRole.name
  policy_arn = aws_iam_policy.bksbUpdatesLambdaServicePolicy.arn
}

resource "aws_lambda_function" "bksbUpdatesLambda" {
  function_name = "bksbUpdatesLambda"
  s3_bucket     = "cdk-hnb659fds-assets-203616038615-eu-west-2"
  s3_key        = "0f9add17a7fa4b33fe6009ddf460e6c732fc1048e2c454332ec502bfb0dfa0d5.zip"
  role          = aws_iam_role.bksbUpdatesLambdaServiceRole.arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.9"

  environment {
    variables = {
      UPDATES_BUCKET               = "bksb-prod-updates-eu-west-2"
      UPDATES_BUCKET_VERSIONS_PATH = "releases"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.bksbUpdatesLambdaServicePolicyAttachment
  ]
}

resource "aws_lambda_permission" "bksbUpdatesLambdaInvoke" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bksbUpdatesLambda.arn
  principal     = "elasticloadbalancing.amazonaws.com"
}

resource "aws_lb_target_group" "bksbUpdatesLambdaTargetGroup" {
  name     = "bksbUpdatesLambdaTargetGroup"
  target_type = "lambda"

  health_check {
    path                = "/healthCheck"
    interval            = 20
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 4
  }

  depends_on = [
    aws_lambda_permission.bksbUpdatesLambdaInvoke
  ]
}

resource "aws_lb_listener_rule" "bksbUpdatesLambdaListenerRule" {
  listener_arn = var.listener_arn
  priority     = 17

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bksbUpdatesLambdaTargetGroup.arn
  }

  condition {
    path_pattern {
      values = ["/bksbupdates"]
    }
  }

  condition {
    http_header {
      http_header_name = "x-bksb-internal"
      values           = ["{{resolve:secretsmanager:arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/loadbalancer/load_balancer_secret:SecretString:::}}"]
    }
  }
}

resource "aws_lb_listener_rule" "bksbUpdatesLambdaTestListenerRule" {
  listener_arn = var.listener_arn
  priority     = 18

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
    target_group_arn = aws_lb_target_group.bksbUpdatesLambdaTargetGroup.arn
  }

  condition {
    host_header {
      values = ["updates.bksb.co.uk"]
    }
  }

  condition {
    http_header {
      http_header_name = "x-bksb-internal"
      values           = ["{{resolve:secretsmanager:arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/loadbalancer/load_balancer_secret:SecretString:::}}"]
    }
  }
}

resource "aws_iam_role" "bksbUpdatesLambdaExecutionRole" {
  name = "bksbUpdatesLambdaExecutionRole"

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

resource "aws_iam_role_policy" "bksbUpdatesLambdaExecutionRolePolicy" {
  name = "bksbUpdatesLambdaExecutionRolePolicy"
  role = aws_iam_role.bksbUpdatesLambdaExecutionRole.name

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

resource "aws_ecs_task_definition" "bksbUpdatesLambdaTaskDefinition" {
  family                   = "prod_bksb-reforms-api"
  network_mode             = "awsvpc"
  requires_compatibilities  = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "8192"
  execution_role_arn       = aws_iam_role.bksbUpdatesLambdaExecutionRole.arn
  task_role_arn            = aws_iam_role.bksbUpdatesLambdaServiceRole.arn

  container_definitions = jsonencode([
    {
      name      = "bksb-reforms-web-client"
      image     = "592311462240.dkr.ecr.eu-west-2.amazonaws.com/bksb/dev/bksb-reforms-web-clients:128-linux-x86_64"
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
          awslogs-group         = aws_cloudwatch_log_group.BKSBReformsClientECSContainerTaskDefinitionBKSBReformsClientECSContainerLogGroup7E105506.name
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
          awslogs-group         = aws_cloudwatch_log_group.BKSBReformsClientECSContainerTaskDefinitionBKSBLive2ReformsAPIXRayECSContainerLogGroup4DBCBDC0.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix  = "bksb-ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "BKSBReformsClientECSContainerTaskDefinitionBKSBReformsClientECSContainerLogGroup" {
  name              = "BKSBReformsClientECSContainerTaskDefinitionBKSBReformsClientECSContainerLogGroup"
  retention_in_days = 7
}

resource "aws_ecs_service" "BKSBReformsClientECSService" {
  name            = "BKSBReformsClientECSService"
  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.bksbUpdatesLambdaTaskDefinition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = "DISABLED"
    security_groups  = [aws_security_group.BKSBReformsAPISG.id]
    subnets          = var.subnet_ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.bksbUpdatesLambdaTargetGroup.arn
    container_name   = "bksb-reforms-web-client"
    container_port   = 443
  }
}

resource "aws_application_autoscaling_target" "BKSBReformsClientECSServiceTaskCountTarget" {
  max_capacity       = 12
  min_capacity       = 1
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.BKSBReformsClientECSService.name}"
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

resource "aws_iam_role_policy" "CDRolePolicy" {
  name = "AWSCodeDeployRoleForECS"
  role = aws_iam_role.CDRole.id

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
  app_name              = aws_codedeploy_app.CDApplication.name
  service_role_arn      = aws_iam_role.CDRole.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name = "BKSBReformsClientECSDeploymentGroup"

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
      action                           = "TERMINATE"
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
        listener_arns = [var.prod_listener_arn]
      }

      target_group {
        name = aws_lb_target_group.bksbUpdatesLambdaTargetGroup.name
      }

      test_traffic_route {
        listener_arns = [var.test_listener_arn]
      }
    }
  }
}
