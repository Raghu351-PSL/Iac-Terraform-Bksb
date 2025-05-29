variable "vpc_id" {
  description = "The VPC ID where resources will be created."
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

variable "namespace_id" {
  description = "The ID of the Service Discovery namespace."
  type        = string
}