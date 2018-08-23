output "ecs_security_group_id" {
  description = "Security Group ID assigned to the ECS tasks."
  value       = "${aws_security_group.ecs_sg.id}"
}

output "task_execution_role_arn" {
  description = "The ARN of the task execution role that the Amazon ECS container agent and the Docker daemon can assume."
  value       = "${join("", aws_iam_role.task_execution_role.*.arn)}"
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
  description = "ARN of the CloudWatch Logs log group containers should use."
  value       = "${aws_cloudwatch_log_group.main.arn}"
}
