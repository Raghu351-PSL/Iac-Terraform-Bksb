resource "aws_security_group" "NewECSTaskSG" {
  name        = "NewECSTaskSG"  # Updated name
  description = "NewProdBKSBBuilderV5AppStackLondon/ECSTaskSG"  # Updated description
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
    cidr_blocks = ["10.20.20.0/24"]  # Updated CIDR block
    description = "SQL Server egress rule for New BL2 Database Subnet"
  }

  egress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["10.20.21.0/24"]  # Updated CIDR block
    description = "SQL Server egress rule for New BL2 Database Subnet"
  }

  egress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["10.20.11.0/24"]  # Updated CIDR block
    description = "SQL Server egress rule for New Internal Database Subnet"
  }

  egress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["10.20.12.0/24"]  # Updated CIDR block
    description = "SQL Server egress rule for New Internal Database Subnet"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.20.14.0/24"]  # Updated CIDR block
    description = "HTTP ingress rule for New Cloudflare Tunnel"
  }
}

resource "aws_iam_role" "NewECSContainerTaskDefinitionTaskRole" {
  name = "NewECSContainerTaskDefinitionTaskRole"  # Updated name

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

resource "aws_iam_policy" "NewECSContainerTaskDefinitionTaskRoleDefaultPolicy" {
  name = "NewECSContainerTaskDefinitionTaskRoleDefaultPolicy"  # Updated name

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
          "arn:aws:s3:::newbksbbuildercontentdev",  # Updated resource
          "arn:aws:s3:::newbksbbuildercontentdev/*",  # Updated resource
          "arn:aws:s3:::newbksbcloudfront",  # Updated resource
          "arn:aws:s3:::newbksbcloudfront/*",  # Updated resource
          "arn:aws:s3:::newbksbdevenginecontent",  # Updated resource
          "arn:aws:s3:::newbksbdevenginecontent/*",  # Updated resource
          "arn:aws:s3:::newcdn.private.bksb.co.uk",  # Updated resource
          "arn:aws:s3:::newcdn.private.bksb.co.uk/*"  # Updated resource
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
        Resource = "*"  # No change
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AttachNewECSContainerTaskPolicy" {
  role       = aws_iam_role.NewECSContainerTaskDefinitionTaskRole.name  # Updated reference
  policy_arn = aws_iam_policy.NewECSContainerTaskDefinitionTaskRoleDefaultPolicy.arn  # Updated reference
}

resource "aws_ecs_task_definition" "NewECSContainerTaskDefinition" {
  family                   = "new_prod_bksb-builderv5"  # Updated family name
  network_mode             = "awsvpc"
  requires_compatibilities  = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ECSContainerTaskDefinitionExecutionRole.arn
  task_role_arn            = aws_iam_role.NewECSContainerTaskDefinitionTaskRole.arn  # Updated reference

  container_definitions = jsonencode([
    {
      name      = "new_bksb-builderv5"  # Updated container name
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
          value = "newbuilder5.prod.euw2.bksb.dev"  # Updated value
        },
        {
          name  = "BKSB__XSRF__CookieName"
          value = "X-CSRF-TOKEN-NEW-BKSB-AUTH"  # Updated value
        },
        {
          name  = "BKSB__XSRF__CookiePath"
          value = "/"
        },
        {
          name  = "BKSB__XSRF__HeaderName"
          value = "X-CSRF-TOKEN-NEW-BKSB-AUTH"  # Updated value
        },
        {
          name  = "BKSB__AUTH__ClaimIssuer"
          value = "newbuilder5.prod.euw2.bksb.dev"  # Updated value
        },
        {
          name  = "BKSB__AUTH__CookieDomain"
          value = "newbuilder5.prod.euw2.bksb.dev"  # Updated value
        },
        {
          name  = "BKSB__AUTH__CookieKeyPath"
          value = "path"
        },
        {
          name  = "BKSB__AUTH__CookieKeyPartition"
          value = "newbuilder5.prod.euw2.bksb.dev"  # Updated value
        },
        {
          name  = "BKSB__AUTH__CookieKeyRegion"
          value = "eu-west-1"
        },
        {
          name  = "BKSB__AUTH__CookieName"
          value = "new_auth-session"  # Updated value
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
          value = "newcdn.private.bksb.co.uk"  # Updated value
        },
        {
          name  = "BKSB__APP__CDNFileStore__RootPath"
          value = "new_ecl/0.3.4/"  # Updated value
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
          value = "newbksbbuildercontentdev"  # Updated value
        },
        {
          name  = "BKSB__APP__QuestionFileStore__RootPath"
          value = "new_builderv5/questions_dev/"  # Updated value
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
          value = "newbksbdevenginecontent"  # Updated value
        },
        {
          name  = "BKSB__APP__PublishedQuestionFileStore__RootPath"
          value = "new_assessment-engine/questions/"  # Updated value
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
          value = "newbksbbuildercontentdev"  # Updated value
        },
        {
          name  = "BKSB__APP__ResourceFileStore__RootPath"
          value = "new_builderv5/resources_dev/"  # Updated value
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
          value = "newbksbdevenginecontent"  # Updated value
        },
        {
          name  = "BKSB__APP__PublishedResourceFileStore__RootPath"
          value = "new_resource-engine/questions/"  # Updated value
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
          value = "newbksbbuildercontentdev"  # Updated value
        },
        {
          name  = "BKSB__APP__MediaFileStore__RootPath"
          value = "new_builderv5/media_dev/"  # Updated value
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
          value = "newbksbcloudfront"  # Updated value
        },
        {
          name  = "BKSB__APP__PublishedMediaFileStore__RootPath"
          value = "/"  # No change
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ECSContainerTaskDefinitionAppECSContainerLogGroup.name
          awslogs-stream-prefix  = "new_bksb-management"  # Updated value
          awslogs-region        = "eu-west-2"
        }
      }
      secrets = [
        {
          name      = "BKSB__DB__LiveConnectionString"
          valueFrom = "arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/new_bksb-builderv5/bl2_database_secret"  # Updated value
        },
        {
          name      = "BKSB__DB__BuilderConnectionString"
          valueFrom = "arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/new_bksb-builderv5/internal_database_secret"  # Updated value
        }
      ]
    }
  ])
}

resource "aws_cloudwatch_log_group" "NewECSContainerTaskDefinitionAppECSContainerLogGroup" {
  name              = "NewECSContainerTaskDefinitionAppECSContainerLogGroup"  # Updated name
  retention_in_days = 7
}

resource "aws_iam_role" "NewECSContainerTaskDefinitionExecutionRole" {
  name = "NewECSContainerTaskDefinitionExecutionRole"  # Updated name

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

resource "aws_iam_policy" "NewECSContainerTaskDefinitionExecutionRoleDefaultPolicy" {
  name = "NewECSContainerTaskDefinitionExecutionRoleDefaultPolicy"  # Updated name

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
        Resource = "arn:aws:ecr:eu-west-2:592311462240:repository/new_bksb/dev/new_bksb-builderv5"  # Updated resource
      },
      {
        Action = "ecr:GetAuthorizationToken"
        Effect = "Allow"
        Resource = "*"  # No change
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect = "Allow"
        Resource = aws_cloudwatch_log_group.NewECSContainerTaskDefinitionAppECSContainerLogGroup.arn  # Updated reference
      },
      {
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/new_bksb-builderv5/bl2_database_secret-??????",  # Updated value
          "arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/new_bksb-builderv5/internal_database_secret-??????"  # Updated value
        ]
      },
      {
        Action = "secretsmanager:GetSecretValue"
        Effect = "Allow"
        Resource = [
          "arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/new_bksb-builderv5/bl2_database_secret",  # Updated value
          "arn:aws:secretsmanager:eu-west-2:203616038615:secret:prod/new_bksb-builderv5/internal_database_secret"  # Updated value
        ]
      },
      {
        Action = "kms:Decrypt"
        Effect = "Allow"
        Resource = "arn:aws:kms:eu-west-2:203616038615:key/new-68650925-9e9b-4ddf-9066-f87ae2cb36de"  # Updated value
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AttachNewExecutionRolePolicy" {
  role       = aws_iam_role.NewECSContainerTaskDefinitionExecutionRole.name  # Updated reference
  policy_arn = aws_iam_policy.NewECSContainerTaskDefinitionExecutionRoleDefaultPolicy.arn  # Updated reference
}

resource "aws_ecs_service" "NewECSService" {
  name            = "NewECSService"  # Updated name
  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.NewECSContainerTaskDefinition.arn  # Updated reference
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = "DISABLED"
    security_groups  = [aws_security_group.NewECSTaskSG.id]  # Updated reference
    subnets          = var.subnet_ids
  }

  service_registries {
    registry_arn = aws_service_discovery_service.NewECSServiceCloudmapService.arn  # Updated reference
  }
}

resource "aws_service_discovery_service" "NewECSServiceCloudmapService" {
  name = "new_builder5.prod"  # Updated name

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