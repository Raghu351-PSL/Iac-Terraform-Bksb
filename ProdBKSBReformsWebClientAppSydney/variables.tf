variable "vpc_id" {
  description = "The VPC ID where resources will be deployed."
  type        = string
}

variable "alb_prod_listener_sg_id" {
  description = "The Security Group ID of the ALB Production Listener."
  type        = string
}
variable "alb_prod_listener_arn" {
  description = "ARN of the production ALB listener."
  type        = string
  default     = ""
}
variable "load_balancer_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret for load balancer internal header."
  type        = string
}

variable "alb_test_listener_arn" {
  description = "ARN of the ALB Test Listener."
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS Cluster to attach the service to."
  type        = string
}

variable "subnet_1_id" {
  description = "ID of Subnet 1 for ECS tasks."
  type        = string
}

variable "subnet_2_id" {
  description = "ID of Subnet 2 for ECS tasks."
  type        = string
}

variable "web_client_image" {
  description = "ECR image for the bksb-reforms-web-client container."
  type        = string
}

variable "xray_daemon_image" {
  description = "ECR image for the aws-xray-daemon container."
  type        = string
}

variable "s3_cdn_private_bucket_name" {
  description = "Name of the private S3 CDN bucket."
  type        = string
}