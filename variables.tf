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
  type        = string
}

variable "cloudwatch_alarm_actions" {
  description = "The list of actions to take for cloudwatch alarms"
  type        = list(string)
  default     = []
}

variable "cloudwatch_alarm_cpu_enable" {
  description = "Enable the CPU Utilization CloudWatch metric alarm"
  default     = true
  type        = bool
}

variable "cloudwatch_alarm_cpu_threshold" {
  description = "The CPU Utilization threshold for the CloudWatch metric alarm"
  default     = 80
  type        = number
}

variable "cloudwatch_alarm_mem_enable" {
  description = "Enable the Memory Utilization CloudWatch metric alarm"
  default     = true
  type        = bool
}

variable "cloudwatch_alarm_mem_threshold" {
  description = "The Memory Utilization threshold for the CloudWatch metric alarm"
  default     = 80
  type        = number
}

variable "logs_cloudwatch_retention" {
  description = "Number of days you want to retain log events in the log group."
  default     = 90
  type        = number
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
  type        = bool
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

variable "ec2_create_task_execution_role" {
  description = "Set to true to create ecs task execution role to ECS EC2 Tasks."
  type        = bool
  default     = false
}

variable "assign_public_ip" {
  description = "Whether this instance should be accessible from the public internet. Default is false."
  default     = false
  type        = bool
}

variable "fargate_platform_version" {
  description = "The platform version on which to run your service. Only applicable when using Fargate launch type."
  default     = "LATEST"
  type        = string
}

variable "fargate_task_cpu" {
  description = "Number of cpu units used in initial task definition. Default is minimum."
  default     = 256
  type        = number
}

variable "fargate_task_memory" {
  description = "Amount (in MiB) of memory used in initial task definition. Default is minimum."
  default     = 512
  type        = number
}

variable "tasks_desired_count" {
  description = "The number of instances of a task definition."
  default     = 1
  type        = number
}

variable "tasks_minimum_healthy_percent" {
  description = "Lower limit on the number of running tasks."
  default     = 100
  type        = number
}

variable "tasks_maximum_percent" {
  description = "Upper limit on the number of running tasks."
  default     = 200
  type        = number
}

variable "container_image" {
  description = "The image of the container."
  default     = "golang:alpine"
  type        = string
}

variable "container_definitions" {
  description = "Container definitions provided as valid JSON document. Default uses golang:alpine running a simple hello world."
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
  type        = bool
}

variable "associate_nlb" {
  description = "Whether to associate a Network Load Balancer (NLB) with the ECS service."
  default     = false
  type        = bool
}

variable "alb_security_group" {
  description = "Application Load Balancer (ALB) security group ID to allow traffic from."
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

variable "additional_security_group_ids" {
  description = "In addition to the security group created for the service, a list of security groups the ECS service should also be added to."
  default     = []
  type        = list(string)
}

variable "lb_target_groups" {
  description = "List of load balancer target group objects containing the lb_target_group_arn, container_port and container_health_check_port. The container_port is the port on which the container will receive traffic. The container_health_check_port is an additional port on which the container can receive a health check. The lb_target_group_arn is either Application Load Balancer (ALB) or Network Load Balancer (NLB) target group ARN tasks will register with."
  default     = []
  type = list(
    object({
      container_port              = number
      container_health_check_port = number
      lb_target_group_arn         = string
      }
    )
  )
}

variable "container_volumes" {
  description = "Volumes that containers in your task may use."
  default     = []
  type = list(
    object({
      name = string
    })
  )

}

variable "hello_world_container_ports" {
  description = "List of ports for the hello world container app to listen on. The app currently supports listening on two ports."
  type        = list(number)
  default     = [8080, 8081]
}

variable "service_registries" {
  description = "List of service registry objects as per <https://www.terraform.io/docs/providers/aws/r/ecs_service.html#service_registries-1>. List can only have a single object until <https://github.com/terraform-providers/terraform-provider-aws/issues/9573> is resolved."
  type = list(object({
    registry_arn   = string
    container_name = string
    container_port = number
    port           = number
  }))
  default = []
}

variable "manage_ecs_security_group" {
  description = "Enable creation and management of the ECS security group and rules"
  default     = true
  type        = bool
}

variable "health_check_grace_period_seconds" {
  description = "Grace period within which failed health checks will be ignored at container start. Only applies to services with an attached loadbalancer."
  default     = null
  type        = number
}

variable "ecs_exec_enable" {
  description = "Enable the ability to execute commands on the containers via Amazon ECS Exec"
  default     = false
  type        = bool
}

variable "task_definition_tags" {
  description = "Tags to apply to the task definition"
  type        = map(string)
  default     = {}
}

# See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-task-storage.html#fargate-task-storage-pv14
variable "ephemeral_storage_size_in_gib" {
  description = "The size of the ephemeral storage volume. Without explicit configuration, Amazon ECS tasks that are hosted on Fargate using platform version 1.4.0 or later receive a minimum of 20 GiB of ephemeral storage. This value can be configured from a minimum of 21 GiB up to a maximum of 200 GiB."
  type        = number
  default     = null
}
