variable "name" {
  description = "The service name."
}

variable "environment" {
  description = "Environment tag, e.g prod."
}

variable "logs_cloudwatch_retention" {
  description = "Specifies the number of days you want to retain log events in the log group."
  default     = 90
}

variable "ecs_use_fargate" {
  description = "Whether to use Fargate for the task definition."
  default     = false
}

variable "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster."
}

variable "ecs_vpc_id" {
  description = "VPC ID to be used by ECS."
}

variable "ecs_subnet_ids" {
  description = "Subnet IDs for the ECS tasks."
  type        = "list"
}

variable "fargate_task_cpu" {
  description = "The number of cpu units used by the task. Default is minimum."
  default     = 256
}

variable "fargate_task_memory" {
  description = "The amount (in MiB) of memory used by the task. Default is minimum."
  default     = 512
}

variable "tasks_desired_count" {
  description = "The number of instances of a task definition."
  default     = 1
}

variable "tasks_minimum_healthy_percent" {
  description = "Lower limit on the number of running tasks."
  default     = "100"
}

variable "tasks_maximum_percent" {
  description = "Upper limit on the number of running tasks."
  default     = "200"
}

variable "container_port" {
  description = "The port on which the container will receive traffic."
  default     = 80
}

variable alb_security_group {
  description = "ALB security group ID to allow traffic from."
}

variable alb_target_group {
  description = "ALB target group ARN tasks will register with."
}
