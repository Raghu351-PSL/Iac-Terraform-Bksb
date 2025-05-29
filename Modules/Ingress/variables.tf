# variables.tf

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"  # New region or your required region
}

variable "cluster_name" {
  description = "Name of the ECS Cluster"
  type        = string
  default     = "new-bksb-cluster"
}

variable "task_definition_family" {
  description = "Family name for ECS task definition"
  type        = string
  default     = "new-bksb-builder-task"
}

variable "container_image" {
  description = "ECR Container Image"
  type        = string
  default     = "592311462240.dkr.ecr.eu-west-2.amazonaws.com/new-bksb/new-bksb-builder:v1"
}

variable "cpu" {
  description = "CPU units for ECS task"
  type        = number
  default     = 1024  # 1 vCPU
}

variable "memory" {
  description = "Memory for ECS task in MiB"
  type        = number
  default     = 2048  # 2 GiB
}

variable "subnet_ids" {
  description = "Subnets to be used for ECS service"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups for ECS tasks"
  type        = list(string)
}

variable "cloudmap_namespace_id" {
  description = "CloudMap Namespace ID"
  type        = string
}

variable "cloudmap_service_name" {
  description = "CloudMap service name"
  type        = string
  default     = "new-builder-service"
}

variable "aws_log_group" {
  description = "CloudWatch log group name"
  type        = string
  default     = "/ecs/new-bksb-builder-logs"
}

variable "environment_variables" {
  description = "A map of environment variables for the ECS container"
  type = map(string)
  default = {
    "BKSB__APP__CDNFileStore__UseLocal"                       = "false"
    "BKSB__APP__CDNFileStore__Region"                          = "eu-west-1"
    "BKSB__APP__CDNFileStore__RootPartition"                   = "cdn.private.bksb-dev.co.uk"
    "BKSB__APP__CDNFileStore__RootPath"                        = "ecl/0.3.7/"
    "BKSB__APP__QuestionFileStore__UseLocal"                   = "false"
    "BKSB__APP__QuestionFileStore__Region"                     = "eu-west-1"
    "BKSB__APP__QuestionFileStore__RootPartition"              = "bksbdevenginecontent-stage"
    "BKSB__APP__QuestionFileStore__RootPath"                   = "aus/dev/builderv5/questions_dev/"
    "BKSB__APP__PublishedQuestionFileStore__UseLocal"          = "false"
    "BKSB__APP__PublishedQuestionFileStore__Region"            = "eu-west-1"
    "BKSB__APP__PublishedQuestionFileStore__RootPartition"     = "bksbdevenginecontent-stage"
    "BKSB__APP__PublishedQuestionFileStore__RootPath"          = "aus/assessment-engine/questions/"
    "BKSB__APP__ResourceFileStore__UseLocal"                   = "false"
    "BKSB__APP__ResourceFileStore__Region"                     = "eu-west-1"
    "BKSB__APP__ResourceFileStore__RootPartition"              = "bksbdevenginecontent-stage"
    "BKSB__APP__ResourceFileStore__RootPath"                   = "aus/dev/builderv5/resources_dev/"
    "BKSB__APP__PublishedResourceFileStore__UseLocal"          = "false"
    "BKSB__APP__PublishedResourceFileStore__Region"            = "eu-west-1"
    "BKSB__APP__PublishedResourceFileStore__RootPartition"     = "bksbdevenginecontent-stage"
    "BKSB__APP__PublishedResourceFileStore__RootPath"          = "aus/resource-engine/questions/"
    "BKSB__APP__MediaFileStore__UseLocal"                      = "false"
    "BKSB__APP__MediaFileStore__Region"                        = "eu-west-1"
    "BKSB__APP__MediaFileStore__RootPartition"                 = "bksbdevenginecontent-stage"
    "BKSB__APP__MediaFileStore__RootPath"                      = "aus/dev/builderv5/media_dev/"
    "BKSB__APP__PublishedMediaFileStore__UseLocal"             = "false"
    "BKSB__APP__PublishedMediaFileStore__Region"               = "eu-west-1"
    "BKSB__APP__PublishedMediaFileStore__RootPartition"        = "bksbcloudfront-staging"
    "BKSB__APP__PublishedMediaFileStore__RootPath"             = "aus/"
  }
}
 