variable "vpc_id" { default = "vpc-0f0e40356198d127f"}
variable "aws_region" { default = "ap-southeast-2" }
variable "az_a" { default = "ap-southeast-2a" }
#variable "az_b" { default = "ap-southeast-2b" }
variable "az_c" { default = "ap-southeast-2c" }

# VPC
variable "vpc_cidr" { default = "10.10.0.0/16" }

# Subnets
variable "db_subnet_a_cidr" { default = "10.10.3.0/24" }
# variable "db_subnet_b_cidr" { default = "10.10.4.0/24" }
variable "db_subnet_c_cidr" {  default = "10.10.12.0/24"}
variable "redis_subnet_a_cidr" { default = "10.10.5.0/24" }
# variable "redis_subnet_b_cidr" { default = "10.10.6.0/24" }
variable "redis_subnet_c_cidr" { default = "10.10.14.0/24" }
variable "internal_db_subnet_a_cidr" { default = "10.10.7.0/24" }
# variable "internal_db_subnet_b_cidr" { default = "10.10.8.0/24" }
variable "internal_db_subnet_c_cidr" { default = "10.10.13.0/24" }
# Peering, KMS, and Security Groups (new dummy values)
#variable "peering_connection_id" { default = "pcx-newpeeringid12345" }
variable "kms_key_id" { default = "arn:aws:kms:ap-southeast-2:352515133004:key/NEWKEYID" }
variable "performance_kms_key_id" { default = "arn:aws:kms:ap-southeast-2:352515133004:key/NEWPERFKEYID" }

# RDS
variable "rds_username" { default = "newdbadmin" }
variable "rds_password" { default = "newdbpassword123!" }
variable "rds_identifier" { default = "new-db-instance" }
variable "rds_parameter_group" { default = "new-db-parameter-group" }
variable "rds_option_group" { default = "new-db-option-group" }
variable "rds_allocated_storage" { default = 100 }
variable "rds_max_allocated_storage" { default = 200 }
variable "rds_monitoring_interval" { default = 60 }
variable "rds_backup_retention" { default = 7 }
variable "rds_timezone" { default = "UTC" }

# Internal RDS
variable "internal_rds_username" { default = "internaladmin" }
variable "internal_rds_password" { default = "internalpassword123!" }
variable "internal_rds_identifier" { default = "new-internal-db-instance" }
variable "internal_rds_parameter_group" { default = "new-internal-db-parameter-group" }
variable "internal_rds_allocated_storage" { default = 100 }
variable "internal_rds_max_allocated_storage" { default = 200 }
variable "internal_rds_monitoring_interval" { default = 60 }
variable "internal_rds_backup_retention" { default = 7 }
variable "internal_rds_timezone" { default = "UTC" }

# Redis
variable "redis_node_type" { default = "cache.t4g.micro" }
variable "redis_engine_version" { default = "6.2" }
variable "redis_replication_group_id" { default = "new-redis-group" }
variable "redis_description" { default = "New Redis Replication Group" }
variable "redis_subnet_group_name" { default = "new-redis-subnet-group" }
variable "redis_snapshot_retention" { default = 7 }
variable "redis_snapshot_window" { default = "02:00-04:00" }
variable "redis_maintenance_window" { default = "sun:04:00-sun:05:00" }
variable "smtp_service_name" { default = "com.amazonaws.ap-southeast-2.email-smtp" }