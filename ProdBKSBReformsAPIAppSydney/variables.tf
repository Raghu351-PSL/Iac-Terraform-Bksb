variable "vpc_id" {
  description = "The VPC ID where resources will be created."
  type        = string
}

variable "new_alb_security_group_id" {
  description = "The security group ID for the Application Load Balancer (ALB)."
  type        = string
}

variable "new_prod_listener_arn" {
  description = "The ARN of the production ALB listener."
  type        = string
}

variable "new_test_listener_arn" {
  description = "The ARN of the test ALB listener."
  type        = string
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster."
  type        = string
}

variable "subnet_ids" {
  description = "The list of subnet IDs for the ECS service."
  type        = list(string)
}