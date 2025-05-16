# AWS Region
variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "ap-southeast-2"
}

# Availability Zones
variable "availability_zone_a" {
  default = "ap-southeast-2a"
}

variable "availability_zone_b" {
  default = "ap-southeast-2b"
}

# VPC and Subnet CIDRs
variable "vpc_cidr_block" {
  default = "10.10.0.0/16"
}

variable "nat_subnet_cidr" {
  default = "10.10.1.0/24"
}

variable "firewall_subnet_cidr" {
  default = "10.10.2.0/24"
}

# Naming
variable "vpc_name" {
  default = "bksb-staging-vpc"
}

variable "nat_subnet_name" {
  default = "bksb-staging-nat-subnet"
}

variable "firewall_subnet_name" {
  default = "bksb-staging-firewall-subnet"
}

variable "internet_gateway_name" {
  default = "bksb-staging-igw"
}

variable "nat_gateway_name" {
  default = "bksb-staging-nat-gateway"
}

variable "firewall_policy_name" {
  default = "bksb-staging-firewall-policy"
}

variable "firewall_name" {
  default = "bksb-staging-network-firewall"
}

variable "firewall_igw_route_table_name" {
  default = "bksb-staging-firewall-igw-route-table"
}

# Flow logs
variable "log_group_name" {
  default = "bksb-staging-vpc-flow-logs"
}

variable "flowlog_role_name" {
  default = "bksb-staging-flowlog-role"
}

# RDS Configuration
variable "rds_instance_name" {
  default = "bksb-staging-rds-instance"
}

variable "rds_engine" {
  default = "sqlserver-web"
}

variable "rds_engine_version"{
  default = "15.00.4420.2.v1"
}
variable "rds_instance_class" {
  default = "db.t3.medium"
}
variable "rds_allocated_storage" {
  default = 20
}

variable "rds_username" {
  default = "admin"
}

variable "rds_password" {
  default = "Admin12345!" # Follow AWS password policy
}

variable "rds_db_subnet_group_name" {
  default = "bksb-staging-db-subnet-group"
}