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
| ecr\_repo\_arns | The ARNs of the ECR repos.  By default, allows all repositories. | list | `[ "*" ]` | no |
| ecs\_cluster\_name | The name  of the ECS cluster. | string | n/a | yes |
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

### 1.14.0 to 1.15.0

In upgrading to this version you need to pass through the ECS Cluster Name and not the ECS Cluster ARN.
The difference would be changing `ecs_cluster_arn` to `ecs_cluster_name` and passing in the name info.
The module will take care of pulling the ARN from the ECS Cluster data resource on your behalf.

If you decide you do not want metric alarms you can also set two more settings:

```hcl
  cloudwatch_alarm_cpu_enable = false
  cloudwatch_alarm_mem_enable = false
```
