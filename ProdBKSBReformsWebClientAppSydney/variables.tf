variable "vpc_id" {
  description = "The VPC ID where resources will be created."
  type        = string
}

variable "alb_security_group_id" {
  description = "The security group ID for the ALB."
  type        = string
}

variable "prod_listener_arn" {
  description = "The ARN of the production ALB listener."
  type        = string
}

variable "test_listener_arn" {
  description = "The ARN of the test ALB listener."
  type        = string
}