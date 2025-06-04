variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "cluster_name" {
  description = "The name of the ECS cluster."
  type        = string
}

variable "subnet_1_id" {
  description = "The ID of the first subnet for the ECS service."
  type        = string
}

variable "subnet_2_id" {
  description = "The ID of the second subnet for the ECS service."
  type        = string
}

variable "alb_listener_prod_arn" {
  description = "ARN of the production ALB listener."
  type        = string
  default     = ""
}

variable "alb_listener_test_arn" {
  description = "ARN of the test ALB listener."
  type        = string
}
variable "load_balancer_secret_arn" {
  description = "ARN for the load balancer secret."
  type        = string
}

variable "db_connection_string_secret_arn" {
  description = "ARN for the database connection string secret."
  type        = string
}

variable "redis_connection_string_secret_arn" {
  description = "ARN for the Redis connection string secret."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN for the KMS key used for decryption."
  type        = string
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository for the bksb-reforms-service image."
  type        = string
}

variable "alb_security_group_id" {
  description = "The ID of the Security Group associated with the ALB."
  type        = string
}