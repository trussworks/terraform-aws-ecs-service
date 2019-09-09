Creates an ECS service.

Creates the following resources:

* CloudWatch log group.
* Security Groups for the ECS service.
* ECS service.
* Task definition using `golang:1.12.5-alpine` (see below).
* Configurable associations with Network Load Balancers (NLB) and Application Load Balancers (ALB).

We create an initial task definition using the `golang:1.12.5-alpine` image as a way
to validate the initial infrastructure is working: visiting the site shows
a simple Go hello world page. We expect deployments to manage the container
definitions going forward, not Terraform.

## Usage

### ECS service associated with an Application Load Balancer (ALB)

```hcl
module "app_ecs_service" {
  source = "trussworks/ecs-service/aws"

  name        = "app"
  environment = "prod"

  ecs_cluster                   = aws_ecs_cluster.mycluster
  ecs_vpc_id                    = module.vpc.vpc_id
  ecs_subnet_ids                = module.vpc.private_subnets
  tasks_desired_count           = 2
  tasks_minimum_healthy_percent = 50
  tasks_maximum_percent         = 200

  associate_alb      = true
  alb_security_group = module.security_group.id
  lb_target_group    = module.target_group.id
}
```

### ECS Service associated with a Network Load Balancer(NLB)

```hcl
module "app_ecs_service" {
  source = "trussworks/ecs-service/aws"

  name        = "app"
  environment = "prod"

  ecs_cluster                   = aws_ecs_cluster.mycluster
  ecs_vpc_id                    = module.vpc.vpc_id
  ecs_subnet_ids                = module.vpc.private_subnets
  tasks_desired_count           = 2
  tasks_minimum_healthy_percent = 50
  tasks_maximum_percent         = 200

  associate_nlb          = true
  nlb_subnet_cidr_blocks = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  lb_target_group   = module.target_group.id
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| alb\_security\_group | Application Load Balancer (ALB) security group ID to allow traffic from. | string | `""` | no |
| associate\_alb | Whether to associate an Application Load Balancer (ALB) with the ECS service. | string | `"false"` | no |
| associate\_nlb | Whether to associate a Network Load Balancer (NLB) with the ECS service. | string | `"false"` | no |
| cloudwatch\_alarm\_actions | The list of actions to take for cloudwatch alarms | list | `[]` | no |
| cloudwatch\_alarm\_cpu\_enable | Enable the CPU Utilization CloudWatch metric alarm | string | `"true"` | no |
| cloudwatch\_alarm\_cpu\_threshold | The CPU Utilization threshold for the CloudWatch metric alarm | string | `"80"` | no |
| cloudwatch\_alarm\_mem\_enable | Enable the Memory Utilization CloudWatch metric alarm | string | `"true"` | no |
| cloudwatch\_alarm\_mem\_threshold | The Memory Utilization threshold for the CloudWatch metric alarm | string | `"80"` | no |
| cloudwatch\_alarm\_name | Generic name used for CPU and Memory Cloudwatch Alarms | string | `""` | no |
| container\_definitions | Container definitions provided as valid JSON document. Default uses golang:1.12.5-alpine running a simple hello world. | string | `""` | no |
| container\_health\_check\_port | An additional port on which the container can receive a health check.  Zero means the container port can only receive a health check on the port set by the container_port variable. | string | `"0"` | no |
| container\_image | The image of the container. | string | `"golang:1.12.5-alpine"` | no |
| container\_port | The port on which the container will receive traffic. | string | `"80"` | no |
| ecr\_repo\_arns | The ARNs of the ECR repos.  By default, allows all repositories. | list(string) | `[ "*" ]` | no |
| ecs\_cluster | ECS cluster object for this task. | object | n/a | yes |
| ecs\_instance\_role | The name of the ECS instance role. | string | `""` | no |
| ecs\_subnet\_ids | Subnet IDs for the ECS tasks. | list(string) | n/a | yes |
| ecs\_use\_fargate | Whether to use Fargate for the task definition. | string | `"false"` | no |
| ecs\_vpc\_id | VPC ID to be used by ECS. | string | n/a | yes |
| environment | Environment tag, e.g prod. | string | n/a | yes |
| fargate\_task\_cpu | Number of cpu units used in initial task definition. Default is minimum. | string | `"256"` | no |
| fargate\_task\_memory | Amount (in MiB) of memory used in initial task definition. Default is minimum. | string | `"512"` | no |
| lb\_target\_group | Either Application Load Balancer (ALB) or Network Load Balancer (NLB) target group ARN tasks will register with. | string | `""` | no |
| logs\_cloudwatch\_group | CloudWatch log group to create and use. Default: /ecs/{name}-{environment} | string | `""` | no |
| logs\_cloudwatch\_retention | Number of days you want to retain log events in the log group. | string | `"90"` | no |
| name | The service name. | string | n/a | yes |
| nlb\_subnet\_cidr\_blocks | List of Network Load Balancer (NLB) CIDR blocks to allow traffic from. | list(string) | `[]` | no |
| target\_container\_name | Name of the container the Load Balancer should target. Default: {name}-{environment} | string | `""` | no |
| tasks\_desired\_count | The number of instances of a task definition. | string | `"1"` | no |
| tasks\_maximum\_percent | Upper limit on the number of running tasks. | string | `"200"` | no |
| tasks\_minimum\_healthy\_percent | Lower limit on the number of running tasks. | string | `"100"` | no |

## Outputs

| Name | Description |
|------|-------------|
| awslogs\_group | Name of the CloudWatch Logs log group containers should use. |
| awslogs\_group\_arn | ARN of the CloudWatch Logs log group containers should use. |
| ecs\_security\_group\_id | Security Group ID assigned to the ECS tasks. |
| task\_definition\_arn | Full ARN of the Task Definition (including both family and revision). |
| task\_definition\_family | The family of the Task Definition. |
| task\_execution\_role\_arn | The ARN of the task execution role that the Amazon ECS container agent and the Docker daemon can assume. |
| task\_role\_arn | The ARN of the IAM role assumed by Amazon ECS container tasks. |
| task\_role\_name | The name of the IAM role assumed by Amazon ECS container tasks. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Upgrade Path

### 1.15.0 to 2.0.0

v2.0.0 of this module is built against Terraform v0.12. In addition to
requiring this upgrade, the v1.15.0 version of the module took the name
of the ECS cluster as a parameter; v2.0.0 takes the actual object of the
ECS cluster as a parameter instead. You will need to update previous
instances of this module with the altered parameter.
