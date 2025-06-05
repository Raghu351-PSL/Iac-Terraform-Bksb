output "bksb_reforms_client_sg_id" {
  description = "The ID of the BKSB Reforms Client Security Group."
  value       = aws_security_group.bksb_reforms_client_sg.id
}

output "alb_target_group_one_arn" {
  description = "ARN of ALB Target Group One."
  value       = aws_lb_target_group.alb_target_group_one.arn
}

output "alb_target_group_two_arn" {
  description = "ARN of ALB Target Group Two."
  value       = aws_lb_target_group.alb_target_group_two.arn
}

output "ecs_service_name" {
  description = "Name of the ECS Service."
  value       = aws_ecs_service.bksb_reforms_client_ecs_service.name
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS Task Definition."
  value       = aws_ecs_task_definition.bksb_reforms_client_task_definition.arn
}