provider "aws" {
  region = var.aws_region
}

# --- KMS Key for RDS and Redis ---
resource "aws_kms_key" "redis" {
  description             = "KMS key for Redis encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS and Redis encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}


# --- RDS Option Group ---
resource "aws_db_option_group" "rds" {
  name                     = "new-db-option-group"
  engine_name              = "sqlserver-web"
  major_engine_version     = "15.00"
  option_group_description = "Option group for new RDS instance"
}

# --- RDS Parameter Group ---
resource "aws_db_parameter_group" "rds" {
  name        = "new-db-parameter-group"
  family      = "sqlserver-web-15.0"
  description = "Parameter group for new RDS instance"
}

# --- Internal RDS Option Group ---
resource "aws_db_option_group" "internal_rds" {
  name                     = "new-internal-db-option-group"
  engine_name              = "sqlserver-web"
  major_engine_version     = "15.00"
  option_group_description = "Option group for new internal RDS instance"
}

# --- Internal RDS Parameter Group ---
resource "aws_db_parameter_group" "internal_rds" {
  name        = "new-internal-db-parameter-group"
  family      = "sqlserver-web-15.0"
  description = "Parameter group for new internal RDS instance"
}

# --- Database Subnets, Route Tables, NACLs ---
resource "aws_subnet" "db_subnet_a" {
  vpc_id            = var.vpc_id
  cidr_block        = var.db_subnet_a_cidr
  availability_zone = var.az_a
  tags = { Name = "NewDatabaseSubnetA" }
}

# resource "aws_subnet" "db_subnet_b" {
#   vpc_id            = var.vpc_id
#   cidr_block        = var.db_subnet_b_cidr
#   availability_zone = var.az_b
#   tags = { Name = "NewDatabaseSubnetB" }
# }
resource "aws_subnet" "db_subnet_c" {
  vpc_id            = var.vpc_id
  cidr_block        = var.db_subnet_c_cidr
  availability_zone = var.az_c
  tags = { Name = "NewDatabaseSubnetC" }
}

resource "aws_route_table" "db_subnet_a" {
  vpc_id = var.vpc_id
  tags   = { Name = "NewDatabaseSubnetA" }
}

# resource "aws_route_table" "db_subnet_b" {
#   vpc_id = var.vpc_id
#   tags   = { Name = "NewDatabaseSubnetB" }
# }

resource "aws_route_table" "db_subnet_c" {
  vpc_id = var.vpc_id
  tags   = { Name = "NewDatabaseSubnetC" }
}

resource "aws_route_table_association" "db_subnet_a" {
  subnet_id      = aws_subnet.db_subnet_a.id
  route_table_id = aws_route_table.db_subnet_a.id
}

# resource "aws_route_table_association" "db_subnet_b" {
#   subnet_id      = aws_subnet.db_subnet_b.id
#   route_table_id = aws_route_table.db_subnet_b.id
# }

resource "aws_route_table_association" "db_subnet_c" {
  subnet_id      = aws_subnet.db_subnet_c.id
  route_table_id = aws_route_table.db_subnet_c.id
}

resource "aws_network_acl" "db_acl" {
  vpc_id = var.vpc_id
  tags   = { Name = "new-database-subnet-acl" }
}

resource "aws_network_acl_association" "db_subnet_a" {
  network_acl_id = aws_network_acl.db_acl.id
  subnet_id      = aws_subnet.db_subnet_a.id
}

# resource "aws_network_acl_association" "db_subnet_b" {
#   network_acl_id = aws_network_acl.db_acl.id
#   subnet_id      = aws_subnet.db_subnet_b.id
# }

resource "aws_network_acl_association" "db_subnet_c" {
  network_acl_id = aws_network_acl.db_acl.id
  subnet_id      = aws_subnet.db_subnet_c.id
}

resource "aws_network_acl_rule" "db_allow_bastion_ingress" {
  network_acl_id = aws_network_acl.db_acl.id
  rule_number    = 100
  egress         = false
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = "10.10.10.0/24"
  from_port      = 1433
  to_port        = 1433
}

resource "aws_network_acl_rule" "db_allow_all_egress" {
  network_acl_id = aws_network_acl.db_acl.id
  rule_number    = 5000
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# --- Database Security Group ---
resource "aws_security_group" "rds_sg" {
  name        = "NewRDSDatabaseSG"
  description = "Security Group for new RDS Database"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Egress HTTPS"
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Egress HTTP"
  }
  egress {
    from_port   = 587
    to_port     = 587
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Egress SMTP"
  }
}

resource "aws_security_group_rule" "rds_ingress" {
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  security_group_id = aws_security_group.rds_sg.id
  cidr_blocks       = ["10.10.9.0/24"]
  description       = "Ingress from VPC"
}

# --- RDS Subnet Group, Secret, Monitoring Role, Log Groups ---
resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "new-db-subnet-group"
  description = "Subnet group for new RDS database"
  subnet_ids  = [aws_subnet.db_subnet_a.id, aws_subnet.db_subnet_c.id]
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name        = "new/database/rds_admin_credentials"
  description = "New RDS admin credentials"
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id     = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({ username = var.rds_username, password = var.rds_password })
}

resource "aws_iam_role" "internal_rds_monitoring_role" {
  name = "new-internal-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "rds_monitoring_policy_attachment" {
  role       = aws_iam_role.internal_rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
resource "aws_cloudwatch_log_group" "rds_agent" {
  name              = "/aws/rds/instance/${var.rds_identifier}/agent"
  retention_in_days = 365
}
resource "aws_cloudwatch_log_group" "rds_error" {
  name              = "/aws/rds/instance/${var.rds_identifier}/error"
  retention_in_days = 365
}

# --- RDS Instance ---
resource "aws_db_instance" "rds" {
  identifier                   = var.rds_identifier
  allocated_storage            = var.rds_allocated_storage
  max_allocated_storage        = var.rds_max_allocated_storage
  engine                       = "sqlserver-web"
  engine_version               = "15.00.4236.7.v1"
  instance_class               = "db.t3.medium"
  username                     = var.rds_username
  password                     = var.rds_password
  db_subnet_group_name         = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids       = [aws_security_group.rds_sg.id]
  storage_encrypted            = true
  kms_key_id                   = aws_kms_key.redis.arn
  backup_retention_period      = var.rds_backup_retention
  skip_final_snapshot          = true
  copy_tags_to_snapshot        = true
  monitoring_interval          = var.rds_monitoring_interval
  monitoring_role_arn          = aws_iam_role.rds_monitoring_role.arn
  performance_insights_enabled = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn
  performance_insights_retention_period = 731
  option_group_name            = aws_db_option_group.rds.name
  parameter_group_name         = aws_db_parameter_group.rds.name
  timezone                     = var.rds_timezone
  enabled_cloudwatch_logs_exports = ["agent", "error"]
  deletion_protection          = false
}

# --- Internal DB Subnets, Route Tables, NACLs, Security Group ---
resource "aws_subnet" "internal_db_subnet_a" {
  vpc_id            = var.vpc_id
  cidr_block        = var.internal_db_subnet_a_cidr
  availability_zone = var.az_c
  tags = { Name = "NewInternalDatabaseSubnetA" }
}

# resource "aws_subnet" "internal_db_subnet_b" {
#   vpc_id            = var.vpc_id
#   cidr_block        = var.internal_db_subnet_b_cidr
#   availability_zone = var.az_b
#   tags = { Name = "NewInternalDatabaseSubnetB" }
# }

resource "aws_subnet" "internal_db_subnet_c" {
  vpc_id            = var.vpc_id
  cidr_block        = var.internal_db_subnet_c_cidr
  availability_zone = var.az_c
  tags = { Name = "NewInternalDatabaseSubnetC" }
}

resource "aws_route_table" "internal_db_subnet_a" {
  vpc_id = var.vpc_id
  tags   = { Name = "NewInternalDatabaseSubnetA" }
}

# resource "aws_route_table" "internal_db_subnet_b" {
#   vpc_id = var.vpc_id
#   tags   = { Name = "NewInternalDatabaseSubnetB" }
# }

resource "aws_route_table" "internal_db_subnet_c" {
  vpc_id = var.vpc_id
  tags   = { Name = "NewInternalDatabaseSubnetC" }
}


resource "aws_route_table_association" "internal_db_subnet_a" {
  subnet_id      = aws_subnet.internal_db_subnet_a.id
  route_table_id = aws_route_table.internal_db_subnet_a.id
}

# resource "aws_route_table_association" "internal_db_subnet_b" {
#   subnet_id      = aws_subnet.internal_db_subnet_b.id
#   route_table_id = aws_route_table.internal_db_subnet_b.id
# }

resource "aws_route_table_association" "internal_db_subnet_c" {
  subnet_id      = aws_subnet.internal_db_subnet_c.id
  route_table_id = aws_route_table.internal_db_subnet_c.id
}

resource "aws_network_acl" "internal_db_acl" {
  vpc_id = var.vpc_id
  tags   = { Name = "new-internal-database-subnet-acl" }
}

resource "aws_network_acl_association" "internal_db_subnet_a" {
  network_acl_id = aws_network_acl.internal_db_acl.id
  subnet_id      = aws_subnet.internal_db_subnet_a.id
}

# resource "aws_network_acl_association" "internal_db_subnet_b" {
#   network_acl_id = aws_network_acl.internal_db_acl.id
#   subnet_id      = aws_subnet.internal_db_subnet_b.id
# }

resource "aws_network_acl_association" "internal_db_subnet_c" {
  network_acl_id = aws_network_acl.internal_db_acl.id
  subnet_id      = aws_subnet.internal_db_subnet_c.id
}

resource "aws_network_acl_rule" "internal_db_allow_bastion_ingress" {
  network_acl_id = aws_network_acl.internal_db_acl.id
  rule_number    = 100
  egress         = false
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = "10.10.10.0/24"
  from_port      = 1433
  to_port        = 1433
}

resource "aws_network_acl_rule" "internal_db_allow_all_egress" {
  network_acl_id = aws_network_acl.internal_db_acl.id
  rule_number    = 5000
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_security_group" "internal_rds_sg" {
  name        = "NewInternalRDSDatabaseSG"
  description = "Security Group for new Internal RDS Database"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Egress HTTPS"
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Egress HTTP"
  }
}

resource "aws_security_group_rule" "internal_rds_ingress" {
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  security_group_id = aws_security_group.internal_rds_sg.id
  cidr_blocks       = ["10.10.11.0/24"]
  description       = "Ingress from VPC"
}

# --- Internal RDS Subnet Group, Secret, Monitoring Role, Log Groups ---
resource "aws_db_subnet_group" "internal_rds_subnet_group" {
  name        = "new-internal-db-subnet-group"
  description = "Subnet group for new Internal RDS database"
  subnet_ids  = [aws_subnet.internal_db_subnet_a.id, aws_subnet.internal_db_subnet_c.id]
}

resource "aws_secretsmanager_secret" "internal_rds_secret" {
  name        = "new/database/internal_rds_admin_credentials"
  description = "New Internal RDS admin credentials"
}

resource "aws_secretsmanager_secret_version" "internal_rds_secret_version" {
  secret_id     = aws_secretsmanager_secret.internal_rds_secret.id
  secret_string = jsonencode({ username = var.internal_rds_username, password = var.internal_rds_password })
}

resource "aws_iam_role" "rds_monitoring_role" {
  name = "new-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_policy" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
resource "aws_cloudwatch_log_group" "internal_rds_agent" {
  name              = "/aws/rds/instance/${var.internal_rds_identifier}/agent"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "internal_rds_error" {
  name              = "/aws/rds/instance/${var.internal_rds_identifier}/error"
  retention_in_days = 365
}

# --- Internal RDS Instance ---
resource "aws_db_instance" "internal_rds" {
  identifier                   = var.internal_rds_identifier
  allocated_storage            = var.internal_rds_allocated_storage
  max_allocated_storage        = var.internal_rds_max_allocated_storage
  engine                       = "sqlserver-web"
  engine_version               = "15.00.4236.7.v1"
  instance_class               = "db.t3.medium"
  username                     = var.internal_rds_username
  password                     = var.internal_rds_password
  db_subnet_group_name         = aws_db_subnet_group.internal_rds_subnet_group.name
  vpc_security_group_ids       = [aws_security_group.internal_rds_sg.id]
  storage_encrypted            = true
  kms_key_id                   = aws_kms_key.redis.arn
  backup_retention_period      = var.internal_rds_backup_retention
  skip_final_snapshot          = true
  copy_tags_to_snapshot        = true
  monitoring_interval          = var.internal_rds_monitoring_interval
  monitoring_role_arn          = aws_iam_role.internal_rds_monitoring_role.arn
  performance_insights_enabled = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn
  performance_insights_retention_period = 731
  option_group_name            = aws_db_option_group.internal_rds.name
  parameter_group_name         = aws_db_parameter_group.internal_rds.name
  timezone                     = var.internal_rds_timezone
  enabled_cloudwatch_logs_exports = ["agent", "error"]
  deletion_protection          = false
}

# --- Redis Subnets, Route Tables, NACLs, Security Group ---
resource "aws_subnet" "redis_subnet_a" {
  vpc_id            = var.vpc_id
  cidr_block        = var.redis_subnet_a_cidr
  availability_zone = var.az_a
  tags = { Name = "NewRedisSubnetA" }
}

# resource "aws_subnet" "redis_subnet_b" {
#   vpc_id            = var.vpc_id
#   cidr_block        = var.redis_subnet_b_cidr
#   availability_zone = var.az_b
#   tags = { Name = "NewRedisSubnetB" }
# }

resource "aws_subnet" "redis_subnet_c" {
  vpc_id            = var.vpc_id
  cidr_block        = var.redis_subnet_c_cidr
  availability_zone = var.az_c
  tags = { Name = "NewRedisSubnetC" }
}

resource "aws_route_table" "redis_subnet_a" {
  vpc_id = var.vpc_id
  tags   = { Name = "NewRedisSubnetA" }
}

# resource "aws_route_table" "redis_subnet_b" {
#   vpc_id = var.vpc_id
#   tags   = { Name = "NewRedisSubnetB" }
# }

resource "aws_route_table" "redis_subnet_c" {
  vpc_id = var.vpc_id
  tags   = { Name = "NewRedisSubnetC" }
}


resource "aws_route_table_association" "redis_subnet_a" {
  subnet_id      = aws_subnet.redis_subnet_a.id
  route_table_id = aws_route_table.redis_subnet_a.id
}

# resource "aws_route_table_association" "redis_subnet_b" {
#   subnet_id      = aws_subnet.redis_subnet_b.id
#   route_table_id = aws_route_table.redis_subnet_b.id
# }

resource "aws_route_table_association" "redis_subnet_c" {
  subnet_id      = aws_subnet.redis_subnet_c.id
  route_table_id = aws_route_table.redis_subnet_c.id
}

resource "aws_network_acl" "redis_acl" {
  vpc_id = var.vpc_id
  tags   = { Name = "new-redis-subnet-acl" }
}

resource "aws_network_acl_association" "redis_subnet_a" {
  network_acl_id = aws_network_acl.redis_acl.id
  subnet_id      = aws_subnet.redis_subnet_a.id
}

# resource "aws_network_acl_association" "redis_subnet_b" {
#   network_acl_id = aws_network_acl.redis_acl.id
#   subnet_id      = aws_subnet.redis_subnet_b.id
# }

resource "aws_network_acl_association" "redis_subnet_c" {
  network_acl_id = aws_network_acl.redis_acl.id
  subnet_id      = aws_subnet.redis_subnet_c.id
 }

resource "aws_network_acl_rule" "redis_http_egress" {
  network_acl_id = aws_network_acl.redis_acl.id
  rule_number    = 100
  egress         = true
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "redis_https_egress" {
  network_acl_id = aws_network_acl.redis_acl.id
  rule_number    = 200
  egress         = true
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "redis_ephemeral_ingress" {
  network_acl_id = aws_network_acl.redis_acl.id
  rule_number    = 100
  egress         = false
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 32768
  to_port        = 65535
}

resource "aws_security_group" "redis_sg" {
  name        = "NewRedisSG"
  description = "Security Group for new Redis"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All TCP Outbound"
  }
}

# --- Redis Subnet Group, Log Groups, Replication Group ---
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name        = var.redis_subnet_group_name
  description = "New Redis Subnet Group"
  subnet_ids  = [aws_subnet.redis_subnet_a.id, aws_subnet.redis_subnet_c.id]
}

resource "aws_cloudwatch_log_group" "redis_slow_logs" {
  name              = "/aws/elasticache/redis/slowlog"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "redis_engine_logs" {
  name              = "/aws/elasticache/redis/enginelog"
  retention_in_days = 365
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = var.redis_replication_group_id
  description                = var.redis_description
  node_type                  = var.redis_node_type
  num_node_groups            = 1
  replicas_per_node_group    = 1
  engine                     = "redis"
  engine_version             = var.redis_engine_version
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids         = [aws_security_group.redis_sg.id]
  automatic_failover_enabled = true
  multi_az_enabled           = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = false
  snapshot_retention_limit   = var.redis_snapshot_retention
  snapshot_window            = var.redis_snapshot_window
  maintenance_window         = var.redis_maintenance_window
  kms_key_id                 = aws_kms_key.redis.arn

  log_delivery_configuration {
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
    destination      = aws_cloudwatch_log_group.redis_slow_logs.name
  }
  log_delivery_configuration {
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "engine-log"
    destination      = aws_cloudwatch_log_group.redis_engine_logs.name
  }
  tags = {
    Name = "NewRedisReplicationGroup"
  }
}

# --- SMTP VPC Endpoint and Security Group ---
resource "aws_security_group" "smtp_vpc_endpoint_sg" {
  name        = "smtp-vpc-endpoint-sg"
  description = "Security group for SMTP VPC endpoint"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
    description = "Allow HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
}

resource "aws_vpc_endpoint" "smtp" {
  vpc_id              = var.vpc_id
  service_name        = var.smtp_service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.smtp_vpc_endpoint_sg.id]
  subnet_ids          = [aws_subnet.db_subnet_a.id, aws_subnet.db_subnet_c.id]
}