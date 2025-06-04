output "bksb_reforms_api_sg_id" {
  description = "The ID of the BKSB Reforms API Security Group."
  value       = aws_security_group.bksb_reforms_api_sg.id
}

output "alb_target_group_one_arn" {
  description = "The ARN of ALB Target Group One."
  value       = aws_lb_target_group.alb_target_group_one.arn
}

output "alb_target_group_two_arn" {
  description = "The ARN of ALB Target Group Two."
  value       = aws_lb_target_group.alb_target_group_two.arn
}

output "ecs_task_role_arn" {
  description = "The ARN of the ECS Task Role."
  value       = aws_iam_role.ecs_task_role.arn
}

output "ecs_execution_role_arn" {
  description = "The ARN of the ECS Execution Role."
  value       = aws_iam_role.ecs_execution_role.arn
}

output "ecs_task_definition_arn" {
  description = "The ARN of the ECS Task Definition."
  value       = aws_ecs_task_definition.bksb_reforms_api_task_definition.arn
}

output "ecs_service_name" {
  description = "The name of the ECS Service."
  value       = aws_ecs_service.bksb_reforms_api_ecs_service.name
}

output "codedeploy_app_name" {
  description = "The name of the CodeDeploy Application."
  value       = aws_codedeploy_app.code_deploy_application.name
}

output "codedeploy_deployment_group_name" {
  description = "The name of the CodeDeploy Deployment Group."
  value       = aws_codedeploy_deployment_group.code_deploy_deployment_group.deployment_group_name
}