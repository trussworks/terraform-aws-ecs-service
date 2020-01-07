variable "name" {
  description = "The service name."
  type        = string
}

variable "environment" {
  description = "Environment tag, e.g prod."
  type        = string
}

variable "cloudwatch_alarm_name" {
  description = "Generic name used for CPU and Memory Cloudwatch Alarms"
  default     = ""
  type        = "string"
}

variable "cloudwatch_alarm_actions" {
  description = "The list of actions to take for cloudwatch alarms"
  type        = "list"
  default     = []
}

variable "cloudwatch_alarm_cpu_enable" {
  description = "Enable the CPU Utilization CloudWatch metric alarm"
  type        = "string"
  default     = true
}

variable "cloudwatch_alarm_cpu_threshold" {
  description = "The CPU Utilization threshold for the CloudWatch metric alarm"
  default     = 80
  type        = "string"
}

variable "cloudwatch_alarm_mem_enable" {
  description = "Enable the Memory Utilization CloudWatch metric alarm"
  type        = "string"
  default     = true
}

variable "cloudwatch_alarm_mem_threshold" {
  description = "The Memory Utilization threshold for the CloudWatch metric alarm"
  default     = 80
  type        = "string"
}

variable "logs_cloudwatch_retention" {
  description = "Number of days you want to retain log events in the log group."
  default     = 90
  type        = string
}

variable "logs_cloudwatch_group" {
  description = "CloudWatch log group to create and use. Default: /ecs/{name}-{environment}"
  default     = ""
  type        = string
}

variable "ecr_repo_arns" {
  description = "The ARNs of the ECR repos.  By default, allows all repositories."
  type        = list(string)
  default     = ["*"]
}

variable "ecs_use_fargate" {
  description = "Whether to use Fargate for the task definition."
  default     = false
  type        = string
}

variable "ecs_cluster" {
  description = "ECS cluster object for this task."
  type = object({
    arn  = string
    name = string
  })
}

variable "ecs_instance_role" {
  description = "The name of the ECS instance role."
  default     = ""
  type        = string
}

variable "ecs_vpc_id" {
  description = "VPC ID to be used by ECS."
  type        = string
}

variable "ecs_subnet_ids" {
  description = "Subnet IDs for the ECS tasks."
  type        = list(string)
}

variable "fargate_task_cpu" {
  description = "Number of cpu units used in initial task definition. Default is minimum."
  default     = 256
  type        = string
}

variable "fargate_task_memory" {
  description = "Amount (in MiB) of memory used in initial task definition. Default is minimum."
  default     = 512
  type        = string
}

variable "tasks_desired_count" {
  description = "The number of instances of a task definition."
  default     = 1
  type        = string
}

variable "tasks_minimum_healthy_percent" {
  description = "Lower limit on the number of running tasks."
  default     = "100"
  type        = string
}

variable "tasks_maximum_percent" {
  description = "Upper limit on the number of running tasks."
  default     = "200"
  type        = string
}

variable "container_image" {
  description = "The image of the container."
  default     = "golang:alpine"
  type        = string
}

variable "container_port" {
  description = "The port on which the container will receive traffic."
  default     = 80
  type        = string
}

variable "container_health_check_port" {
  description = "An additional port on which the container can receive a health check.  Zero means the container port can only receive a health check on the port set by the container_port variable."
  default     = 0
  type        = string
}

variable "container_definitions" {
  description = "Container definitions provided as valid JSON document. Default uses golang:1.12.5-alpine running a simple hello world."
  default     = ""
  type        = string
}

variable "target_container_name" {
  description = "Name of the container the Load Balancer should target. Default: {name}-{environment}"
  default     = ""
  type        = string
}

variable "associate_alb" {
  description = "Whether to associate an Application Load Balancer (ALB) with the ECS service."
  default     = false
  type        = string
}

variable "associate_nlb" {
  description = "Whether to associate a Network Load Balancer (NLB) with the ECS service."
  default     = false
  type        = string
}

variable "alb_security_group" {
  description = "Application Load Balancer (ALB) security group ID to allow traffic from."
  default     = ""
  type        = string
}

variable "lb_target_group" {
  description = "Either Application Load Balancer (ALB) or Network Load Balancer (NLB) target group ARN tasks will register with."
  default     = ""
  type        = string
}

variable "nlb_subnet_cidr_blocks" {
  description = "List of Network Load Balancer (NLB) CIDR blocks to allow traffic from."
  default     = []
  type        = list(string)
}

variable "kms_key_id" {
  description = "KMS customer managed key (CMK) ARN for encrypting application logs."
  type        = string
}
