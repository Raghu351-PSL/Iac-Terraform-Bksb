resource "aws_security_group" "ECSTaskSG" {
  name        = "ECSTaskSG"
  description = "ProdBKSBBuilderV5AppStackLondon/ECSTaskSG"
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
    description = "SQL Server egress rule for BL2 Database Subnet"
  }

  egress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["10.10.21.0/24"]
    description = "SQL Server egress rule for BL2 Database Subnet"
  }

  egress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["10.10.11.0/24"]
    description = "SQL Server egress rule for Internal Database Subnet"
  }

  egress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["10.10.12.0/24"]
    description = "SQL Server egress rule for Internal Database Subnet"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.10.14.0/24"]
    description = "HTTPS ingress rule for Cloudflare Tunnel"
  }
}

resource "aws_iam_role" "ECSContainerTaskDefinitionTaskRole" {
  name = "ECSContainerTaskDefinitionTaskRole"

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

resource "aws_iam_policy" "ECSContainerTaskDefinitionTaskRoleDefaultPolicy" {
  name = "ECSContainerTaskDefinitionTaskRoleDefaultPolicy"

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
          "arn:aws:s3:::bksbcloudfront",
          "arn:aws:s3:::bksbcloudfront/*",
          "arn:aws:s3:::bksbdevenginecontent",
          "arn:aws:s3:::bksbdevenginecontent/*",
          "arn:aws:s3:::cdn.private.bksb.co.uk",
          "arn:aws:s3:::cdn.private.bksb.co.uk/*"
        ]
      },
      {
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AttachECSContainerTaskPolicy" {
  role       = aws_iam_role.ECSContainerTaskDefinitionTaskRole.name
  policy_arn = aws_iam_policy.ECSContainerTaskDefinitionTaskRoleDefaultPolicy.arn
}

resource "aws_ecs_task_definition" "ECSContainerTaskDefinition" {
  family                   = "prod_bksb-builderv5"
  network_mode             = "awsvpc"
  requires_compatibilities  = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ECSContainerTaskDefinitionExecutionRole.arn
  task_role_arn            = aws_iam_role.ECSContainerTaskDefinitionTaskRole.arn

  container_definitions = jsonencode([
    {
      name      = "bksb-builderv5"
      cpu       = 1024
      memory    = 2048
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "Logging__IncludeScopes"
          value = "false"
        },
        {
          name  = "Logging__LogLevel__Default"
          value = "Error"
        },
        {
          name  = "Logging__LogLevel__System"
          value = "Error"
        },
        {
          name  = "Logging__LogLevel__Microsoft"
          value = "Error"
        },
        {
          name  = "Cookies__SameSitePolicy"
          value = "strict"
        },
        {
          name  = "Cookies__SecurePolicy"
          value = "always"
        },
        {
          name  = "BKSB__XSRF__CookieDomain"
          value = "builder5.prod.euw2.bksb.dev"
        },
        {
          name  = "BKSB__XSRF__CookieName"
          value = "X-CSRF-TOKEN-BKSB-AUTH"
        },
        {
          name  = "BKSB__XSRF__CookiePath"
          value = "/"
        },
        {
          name  = "BKSB__XSRF__HeaderName"
          value = "X-CSRF-TOKEN-BKSB-AUTH"
        },
        {
          name  = "BKSB__AUTH__ClaimIssuer"
          value = "builder5.prod.euw2.bksb.dev"
        },
        {
          name  = "BKSB__AUTH__CookieDomain"
          value = "builder5.prod.euw2.bksb.dev"
        },
        {
          name  = "BKSB__AUTH__CookieKeyPath"
          value = "path"
        },
        {
          name  = "BKSB__AUTH__CookieKeyPartition"
          value = "builder5.prod.euw2.bksb.dev"
        },
        {
          name  = "BKSB__AUTH__CookieKeyRegion"
          value = "eu-west-1"
        },
        {
          name  = "BKSB__AUTH__CookieName"
          value = "auth-session"
        },
        {
          name  = "BKSB__APP__CDNFileStore__UseLocal"
          value = "false"
        },
        {
          name  = "BKSB__APP__CDNFileStore__Region"
          value = "eu-west-1"
        },
        {
          name  = "BKSB__APP__CDNFileStore__RootPartition"
          value = "cdn.private.bksb.co.uk"
        },
        {
          name  = "BKSB__APP__CDNFileStore__RootPath"
          value = "ecl/0.3.4/"
        },
        {
          name  = "BKSB__APP__QuestionFileStore__UseLocal"
          value = "false"
        },
        {
          name  = "BKSB__APP__QuestionFileStore__Region"
          value = "eu-west-1"
        },
        {
          name  = "BKSB__APP__QuestionFileStore__RootPartition"
          value = "bksbbuildercontentdev"
        },
        {
          name  = "BKSB__APP__QuestionFileStore__RootPath"
          value = "builderv5/questions_dev/"
        },
        {
          name  = "BKSB__APP__PublishedQuestionFileStore__UseLocal"
          value = "false"
        },
        {
          name  = "BKSB__APP__PublishedQuestionFileStore__Region"
          value = "eu-west-1"
        },
        {
          name  = "BKSB__APP__PublishedQuestionFileStore__RootPartition"
          value = "bksbdevenginecontent"
        },
        {
          name  = "BKSB__APP__PublishedQuestionFileStore__RootPath"
          value = "assessment-engine/questions/"
        },
        {
          name  = "BKSB__APP__ResourceFileStore__UseLocal"
          value = "false"
        },
        {
          name  = "BKSB__APP__ResourceFileStore__Region"
          value = "eu-west-1"
        },
        {
          name  = "BKSB__APP__ResourceFileStore__RootPartition"
          value = "bksbbuildercontentdev"
        },
        {
          name  = "BKSB__APP__ResourceFileStore__RootPath"
          value = "builderv5/resources_dev/"
        },
        {
          name  = "BKSB__APP__PublishedResourceFileStore__UseLocal"
          value = "false"
        },
        {
          name  = "BKSB__APP__PublishedResourceFileStore__Region"
          value = "eu-west-1"
        },
        {
          name  = "BKSB__APP__PublishedResourceFileStore__RootPartition"
          value = "bksbdevenginecontent"
        },
        {
          name  = "BKSB__APP__PublishedResourceFileStore__RootPath"
          value = "resource-engine/questions/"
        },
        {
          name  = "BKSB__APP__MediaFileStore__UseLocal"
          value = "false"
        },
        {
          name  = "BKSB__APP__MediaFileStore__Region"
          value = "eu-west-1"
        },
        {
          name  = "BKSB__APP__MediaFileStore__RootPartition"
          value = "bksbbuildercontentdev"
        },
        {
          name  = "BKSB__APP__MediaFileStore__RootPath"
          value = "builderv5/media_dev/"
        },
        {
          name  = "BKSB__APP__PublishedMediaFileStore__UseLocal"
          value = "false"
        },
        {
          name  = "BKSB__APP__PublishedMediaFileStore__Region"
          value = "eu-west-1"
        },
        {
          name  = "BKSB__APP__PublishedMediaFileStore__RootPartition"
          value = "bksbcloudfront"
        },
        {
          name  = "BKSB__APP__PublishedMediaFileStore__RootPath"
          value = "/"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ECSContainerTaskDefinitionAppECSContainerLogGroup945E8F49.name
          awslogs-stream-prefix  = "bksb-management"
          awslogs-region        = "eu-west-2"
        }
      }
      secrets = [
        {
          name      = "BKSB__DB__LiveConnectionString"
          valueFrom = "arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/bksb-builderv5/bl2_database_secret"
        },
        {
          name      = "BKSB__DB__BuilderConnectionString"
          valueFrom = "arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/bksb-builderv5/internal_database_secret"
        }
      ]
    }
  ])
}

resource "aws_cloudwatch_log_group" "ECSContainerTaskDefinitionAppECSContainerLogGroup" {
  name              = "ECSContainerTaskDefinitionAppECSContainerLogGroup"
  retention_in_days = 7
}

resource "aws_iam_role" "ECSContainerTaskDefinitionExecutionRole" {
  name = "ECSContainerTaskDefinitionExecutionRole"

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

resource "aws_iam_policy" "ECSContainerTaskDefinitionExecutionRoleDefaultPolicy" {
  name = "ECSContainerTaskDefinitionExecutionRoleDefaultPolicy"

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
        Resource = "arn:aws:ecr:eu-west-2:592311462240:repository/bksb/dev/bksb-builderv5"
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
        Resource = aws_cloudwatch_log_group.ECSContainerTaskDefinitionAppECSContainerLogGroup.arn
      },
      {
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/bksb-builderv5/bl2_database_secret-??????",
          "arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/bksb-builderv5/internal_database_secret-??????"
        ]
      },
      {
        Action = "secretsmanager:GetSecretValue"
        Effect = "Allow"
        Resource = [
          "arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/bksb-builderv5/bl2_database_secret",
          "arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/bksb-builderv5/internal_database_secret"
        ]
      },
      {
        Action = "kms:Decrypt"
        Effect = "Allow"
        Resource = "arn:aws:kms:eu-west-2:203616038615:key/68650925-9e9b-4ddf-9066-f87ae2cb36de"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AttachExecutionRolePolicy" {
  role       = aws_iam_role.ECSContainerTaskDefinitionExecutionRole.name
  policy_arn = aws_iam_policy.ECSContainerTaskDefinitionExecutionRoleDefaultPolicy.arn
}

resource "aws_ecs_service" "ECSService" {
  name            = "ECSService"
  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.ECSContainerTaskDefinition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = "DISABLED"
    security_groups  = [aws_security_group.ECSTaskSG.id]
    subnets          = var.subnet_ids
  }

  service_registries {
    registry_arn = aws_service_discovery_service.ECSServiceCloudmapService.arn
  }
}

resource "aws_service_discovery_service" "ECSServiceCloudmapService" {
  name = "builder5.prod"

  dns_config {
    dns_records {
      ttl  = 60
      type = "A"
    }
    namespace_id = var.namespace_id
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}