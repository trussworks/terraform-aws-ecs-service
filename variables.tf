variable "name" {
  description = "The service name."
}

variable "environment" {
  description = "Environment tag, e.g prod."
}

variable "logs_cloudwatch_retention" {
  description = "Number of days you want to retain log events in the log group."
  default     = 90
}

variable "logs_cloudwatch_group" {
  description = "CloudWatch log group to create and use. Default: /ecs/{name}-{environment}"
  default     = ""
}

variable "ecs_use_fargate" {
  description = "Whether to use Fargate for the task definition."
  default     = false
}

variable "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster."
}

variable "ecs_instance_role" {
  description = "The name of the ECS instance role."
  type        = "string"
  default     = ""
}

variable "ecs_vpc_id" {
  description = "VPC ID to be used by ECS."
}

variable "ecs_subnet_ids" {
  description = "Subnet IDs for the ECS tasks."
  type        = "list"
}

variable "fargate_task_cpu" {
  description = "Number of cpu units used in initial task definition. Default is minimum."
  default     = 256
}

variable "fargate_task_memory" {
  description = "Amount (in MiB) of memory used in initiail task definition. Default is minimum."
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

variable "container_definitions" {
  description = "Container definitions provided as valid JSON document. Default uses nginx:stable."
  default     = ""
}

variable alb_security_group {
  description = "ALB security group ID to allow traffic from."
  default     = ""
}

variable alb_target_group {
  description = "ALB target group ARN tasks will register with."
  default     = ""
}
