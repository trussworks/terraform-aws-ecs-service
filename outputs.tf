output "ecs_security_group_id" {
  description = "Security Group ID assigned to the ECS tasks."
  value       = "${aws_security_group.ecs_sg.id}"
}

output "task_role_arn" {
  description = "The ARN of the IAM role assumed by Amazon ECS container tasks."
  value       = "${aws_iam_role.task_role.arn}"
}

output "task_role_name" {
  description = "The name of the IAM role assumed by Amazon ECS container tasks."
  value       = "${aws_iam_role.task_role.name}"
}

output "awslogs_group" {
  description = "Name of the CloudWatch Logs log group containers should use."
  value       = "${local.awslogs_group}"
}
