variable "name" {
  description = "The service name."
  type        = "string"
}

variable "environment" {
  description = "Environment tag, e.g prod."
  type        = "string"
}

variable "logs_cloudwatch_retention" {
  description = "Number of days you want to retain log events in the log group."
  default     = 90
  type        = "string"
}

variable "logs_cloudwatch_group" {
  description = "CloudWatch log group to create and use. Default: /ecs/{name}-{environment}"
  default     = ""
  type        = "string"
}

variable "ecs_use_fargate" {
  description = "Whether to use Fargate for the task definition."
  default     = false
  type        = "string"
}

variable "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster."
  type        = "string"
}

variable "ecs_instance_role" {
  description = "The name of the ECS instance role."
  default     = ""
  type        = "string"
}

variable "ecs_vpc_id" {
  description = "VPC ID to be used by ECS."
  type        = "string"
}

variable "ecs_subnet_ids" {
  description = "Subnet IDs for the ECS tasks."
  type        = "list"
}

variable "fargate_task_cpu" {
  description = "Number of cpu units used in initial task definition. Default is minimum."
  default     = 256
  type        = "string"
}

variable "fargate_task_memory" {
  description = "Amount (in MiB) of memory used in initial task definition. Default is minimum."
  default     = 512
  type        = "string"
}

variable "tasks_desired_count" {
  description = "The number of instances of a task definition."
  default     = 1
  type        = "string"
}

variable "tasks_minimum_healthy_percent" {
  description = "Lower limit on the number of running tasks."
  default     = "100"
  type        = "string"
}

variable "tasks_maximum_percent" {
  description = "Upper limit on the number of running tasks."
  default     = "200"
  type        = "string"
}

variable "container_port" {
  description = "The port on which the container will receive traffic."
  default     = 80
  type        = "string"
}

variable "container_health_check_port" {
  description = "An additional port on which the container can receive a health check.  Zero means the container port can only receive a health check on the port set by the container_port variable."
  default     = 0
  type        = "string"
}

variable "container_definitions" {
  description = "Container definitions provided as valid JSON document. Default uses nginx:stable."
  default     = ""
  type        = "string"
}

variable "target_container_name" {
  description = "Name of the container the Load Balancer should target. Default: {name}-{environment}"
  default     = ""
  type        = "string"
}

variable "associate_alb" {
  description = "Whether to associate an Application Load Balancer (ALB) with the ECS service."
  default     = false
  type        = "string"
}

variable "associate_nlb" {
  description = "Whether to associate a Network Load Balancer (NLB) with the ECS service."
  default     = false
  type        = "string"
}

variable "alb_security_group" {
  description = "Application Load Balancer (ALB) security group ID to allow traffic from."
  default     = ""
  type        = "string"
}

variable "lb_target_group" {
  description = "Either Application Load Balancer (ALB) or Network Load Balancer (NLB) target group ARN tasks will register with."
  default     = ""
  type        = "string"
}

variable "nlb_subnet_cidr_blocks" {
  description = "List of Network Load Balancer (NLB) CIDR blocks to allow traffic from."
  default     = []
  type        = "list"
}
