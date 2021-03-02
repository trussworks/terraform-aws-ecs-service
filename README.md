Terraform module that creates an ECS service with the following features

* Runs an ECS service with or without an AWS load balancer.
* Stream logs to a CloudWatch log group encrypted with a KMS key.
* Associate multiple target groups with Network Load Balancers (NLB) and Application Load Balancers (ALB).
* Supports running ECS tasks on EC2 instances or Fargate.

## Default container definition (hello world app)

We create an initial task definition using the `golang:alpine` image as a way
to validate the initial infrastructure is working: visiting the site shows
a simple Go hello world page listening on two configurable ports. This is
meant to get a proof of concept instance up and running and to help with
testing.

If you want to customize the listener ports for the hello world app, you can
modify the `hello_world_container_ports` variable.

In production usage, we expect deployment tooling to manage the container
definitions going forward, not Terraform.

## Terraform Versions

Terraform 0.13 and 0.14. Pin module version to ~> 6.0. Submit pull-requests to master branch.

Terraform 0.12 is deprecated.

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
  kms_key_id                    = aws_kms_key.main.arn
  tasks_desired_count           = 2

  associate_alb      = true
  alb_security_group = module.security_group.id
  lb_target_groups =
  [
    {
      container_port              = 8443
      container_health_check_port = 8443
      lb_target_group_arn         = module.alb.arn
    }
  ]
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
  kms_key_id                    = aws_kms_key.main.arn
  tasks_desired_count           = 2

  associate_nlb          = true
  nlb_subnet_cidr_blocks = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]

  lb_target_groups =
  [
    {
      container_port              = 8443
      container_health_check_port = 8080
      lb_target_group_arn         = module.nlb.arn
    }
  ]
}
```

### ECS Service without any AWS load balancer

```hcl
module "app_ecs_service" {
  source = "trussworks/ecs-service/aws"

  name        = "app"
  environment = "prod"

  ecs_cluster                   = aws_ecs_cluster.mycluster
  ecs_vpc_id                    = module.vpc.vpc_id
  ecs_subnet_ids                = module.vpc.private_subnets
  kms_key_id                    = aws_kms_key.main.arn
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |
| aws | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.0 |

## Modules

No Modules.

## Resources

| Name |
|------|
| [aws_cloudwatch_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) |
| [aws_cloudwatch_metric_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) |
| [aws_ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) |
| [aws_ecs_task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecs_task_definition) |
| [aws_ecs_task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) |
| [aws_iam_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) |
| [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| [aws_iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) |
| [aws_region](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) |
| [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) |
| [aws_security_group_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_security\_group\_ids | In addition to the security group created for the service, a list of security groups the ECS service should also be added to. | `list(string)` | `[]` | no |
| alb\_security\_group | Application Load Balancer (ALB) security group ID to allow traffic from. | `string` | `""` | no |
| assign\_public\_ip | Whether this instance should be accessible from the public internet. Default is false. | `bool` | `false` | no |
| associate\_alb | Whether to associate an Application Load Balancer (ALB) with the ECS service. | `bool` | `false` | no |
| associate\_nlb | Whether to associate a Network Load Balancer (NLB) with the ECS service. | `bool` | `false` | no |
| cloudwatch\_alarm\_actions | The list of actions to take for cloudwatch alarms | `list(string)` | `[]` | no |
| cloudwatch\_alarm\_cpu\_enable | Enable the CPU Utilization CloudWatch metric alarm | `bool` | `true` | no |
| cloudwatch\_alarm\_cpu\_threshold | The CPU Utilization threshold for the CloudWatch metric alarm | `number` | `80` | no |
| cloudwatch\_alarm\_mem\_enable | Enable the Memory Utilization CloudWatch metric alarm | `bool` | `true` | no |
| cloudwatch\_alarm\_mem\_threshold | The Memory Utilization threshold for the CloudWatch metric alarm | `number` | `80` | no |
| cloudwatch\_alarm\_name | Generic name used for CPU and Memory Cloudwatch Alarms | `string` | `""` | no |
| container\_definitions | Container definitions provided as valid JSON document. Default uses golang:alpine running a simple hello world. | `string` | `""` | no |
| container\_image | The image of the container. | `string` | `"golang:alpine"` | no |
| ecr\_repo\_arns | The ARNs of the ECR repos.  By default, allows all repositories. | `list(string)` | <pre>[<br>  "*"<br>]</pre> | no |
| ecs\_cluster | ECS cluster object for this task. | <pre>object({<br>    arn  = string<br>    name = string<br>  })</pre> | n/a | yes |
| ecs\_instance\_role | The name of the ECS instance role. | `string` | `""` | no |
| ecs\_subnet\_ids | Subnet IDs for the ECS tasks. | `list(string)` | n/a | yes |
| ecs\_use\_fargate | Whether to use Fargate for the task definition. | `bool` | `false` | no |
| ecs\_vpc\_id | VPC ID to be used by ECS. | `string` | n/a | yes |
| environment | Environment tag, e.g prod. | `string` | n/a | yes |
| fargate\_platform\_version | The platform version on which to run your service. Only applicable when using Fargate launch type. | `string` | `"LATEST"` | no |
| fargate\_task\_cpu | Number of cpu units used in initial task definition. Default is minimum. | `number` | `256` | no |
| fargate\_task\_memory | Amount (in MiB) of memory used in initial task definition. Default is minimum. | `number` | `512` | no |
| health\_check\_grace\_period\_seconds | Grace period within which failed health checks will be ignored at container start. Only applies to services with an attached loadbalancer. | `number` | `null` | no |
| hello\_world\_container\_ports | List of ports for the hello world container app to listen on. The app currently supports listening on two ports. | `list(number)` | <pre>[<br>  8080,<br>  8081<br>]</pre> | no |
| kms\_key\_id | KMS customer managed key (CMK) ARN for encrypting application logs. | `string` | n/a | yes |
| lb\_target\_groups | List of load balancer target group objects containing the lb\_target\_group\_arn, container\_port and container\_health\_check\_port. The container\_port is the port on which the container will receive traffic. The container\_health\_check\_port is an additional port on which the container can receive a health check. The lb\_target\_group\_arn is either Application Load Balancer (ALB) or Network Load Balancer (NLB) target group ARN tasks will register with. | <pre>list(<br>    object({<br>      container_port              = number<br>      container_health_check_port = number<br>      lb_target_group_arn         = string<br>      }<br>    )<br>  )</pre> | `[]` | no |
| logs\_cloudwatch\_group | CloudWatch log group to create and use. Default: /ecs/{name}-{environment} | `string` | `""` | no |
| logs\_cloudwatch\_retention | Number of days you want to retain log events in the log group. | `number` | `90` | no |
| manage\_ecs\_security\_group | Enable creation and management of the ECS security group and rules | `bool` | `true` | no |
| name | The service name. | `string` | n/a | yes |
| nlb\_subnet\_cidr\_blocks | List of Network Load Balancer (NLB) CIDR blocks to allow traffic from. | `list(string)` | `[]` | no |
| service\_registries | List of service registry objects as per <https://www.terraform.io/docs/providers/aws/r/ecs_service.html#service_registries-1>. List can only have a single object until <https://github.com/terraform-providers/terraform-provider-aws/issues/9573> is resolved. | <pre>list(object({<br>    registry_arn   = string<br>    container_name = string<br>    container_port = number<br>    port           = number<br>  }))</pre> | `[]` | no |
| target\_container\_name | Name of the container the Load Balancer should target. Default: {name}-{environment} | `string` | `""` | no |
| tasks\_desired\_count | The number of instances of a task definition. | `number` | `1` | no |
| tasks\_maximum\_percent | Upper limit on the number of running tasks. | `number` | `200` | no |
| tasks\_minimum\_healthy\_percent | Lower limit on the number of running tasks. | `number` | `100` | no |

## Outputs

| Name | Description |
|------|-------------|
| awslogs\_group | Name of the CloudWatch Logs log group containers should use. |
| awslogs\_group\_arn | ARN of the CloudWatch Logs log group containers should use. |
| ecs\_security\_group\_id | Security Group ID assigned to the ECS tasks. |
| task\_definition\_arn | Full ARN of the Task Definition (including both family and revision). |
| task\_definition\_family | The family of the Task Definition. |
| task\_execution\_role | The role object of the task execution role that the Amazon ECS container agent and the Docker daemon can assume. |
| task\_execution\_role\_arn | The ARN of the task execution role that the Amazon ECS container agent and the Docker daemon can assume. |
| task\_execution\_role\_name | The name of the task execution role that the Amazon ECS container agent and the Docker daemon can assume. |
| task\_role | The IAM role object assumed by Amazon ECS container tasks. |
| task\_role\_arn | The ARN of the IAM role assumed by Amazon ECS container tasks. |
| task\_role\_name | The name of the IAM role assumed by Amazon ECS container tasks. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Upgrade Path

### 5.x.x to 6.0.0

In versions 5.x.x and prior, the following resources existed as arrays (toggled by a `count` meta-argument). With 6.0.0, each pair has been merged into a single resource.

* `aws_cloudwatch_metric_alarm.alarm_cpu[0]` xor `aws_cloudwatch_metric_alarm.alarm_cpu_no_lb[0]` -> `aws_cloudwatch_metric_alarm.alarm_cpu`
* `aws_cloudwatch_metric_alarm.alarm_mem[0]` xor `aws_cloudwatch_metric_alarm.alarm_mem_no_lb[0]` -> `aws_cloudwatch_metric_alarm.alarm_mem`
* `aws_ecs_service.main[0]` xor `aws_ecs_service.main_no_lb[0]` -> `aws_ecs_service.main`

To upgrade to 6.0.0, you will need to perform a `terraform state mv` for any affected resources to avoid destruction and recreation. Alternatively, you can let Terraform delete/recreate the deployed resources.

For example, if you are using this module and naming it `example`, you could run one or more of the commands as appropriate given your environment:

```bash
# Example alarm_cpu state mv commands (pick the relevant one for your environment):
terraform state mv 'module.example.aws_cloudwatch_metric_alarm.alarm_cpu[0]' 'module.example.aws_cloudwatch_metric_alarm.alarm_cpu'
terraform state mv 'module.example.aws_cloudwatch_metric_alarm.alarm_cpu_no_lb[0]' 'module.example.aws_cloudwatch_metric_alarm.alarm_cpu'

# Example alarm_mem state mv commands (pick the relevant one for your environment):
terraform state mv 'module.example.aws_cloudwatch_metric_alarm.alarm_mem[0]' 'module.example.aws_cloudwatch_metric_alarm.alarm_mem'
terraform state mv 'module.example.aws_cloudwatch_metric_alarm.alarm_mem_no_lb[0]' 'module.example.aws_cloudwatch_metric_alarm.alarm_mem'

# Example main state mv commands (pick the relevant one for your environment):
terraform state mv 'module.example.aws_ecs_service.main[0]' 'module.example.aws_ecs_service.main'
terraform state mv 'module.example.aws_ecs_service.main_no_lb[0]' 'module.example.aws_ecs_service.main'
```

### 5.x.x to 5.1.1

With 5.1.1, the `hashicorp/aws` provider must be a minimum version of 3.0. It no longer has a maximum version. Therefore any code calling this will need to accomodate for that minimum version change.

### 4.0.0 to 5.0.0

Prior to 5.x, the `hashicorp/aws` provider required the use of version 2.70. 5.x changes the `hashicorp/aws` provider so that it can be greater than or equal to 2.70, but must be less than 4.0. Therefore any code calling this will need to accomodate for that version change.

### 3.x.x to 4.0.0

3.x.x uses Terraform 0.12.x and 4.0.0 uses Terraform 0.13.x, so this requires upgrading any code that uses this module to Terraform 0.13.x.

### 2.x.x to 3.0.0

In 3.0.0 the module added support for multiple load balancer target groups. To support this change, `container_port`, `container_health_check_port` and `lb_target_group` are being replaced with `lb_target_groups`.

#### Without a load balancer

If you are using this module without an ALB or NLB then you can remove any references to `container_port`, `container_health_check_port` and `lb_target_group` if you were doing so.

#### Using with ALB or NLB target groups

If you are using an NLB or NLB target groups with this module then you will need replace the values of `container_port`, `container_health_check_port` and `lb_target_group` with

Below is an example of how the module would be instantiated prior to version 3.0.0:

```hcl
module "app_ecs_service" {
  source = "trussworks/ecs-service/aws"
  ...
  container_port                  = 8443
  container_health_check_port     = 8080
  lb_target_group_arn             = module.alb.arn
  ...
}
```

In 3.0.0 the same example will look like the following

```hcl
module "app_ecs_service" {
  source = "trussworks/ecs-service/aws"
  ...
  lb_target_groups =
  [
    {
      container_port                  = 8443
      container_health_check_port     = 8080
      lb_target_group_arn             = module.alb.arn
    }
  ]
  ...
}
```


### 2.0.0 to 2.1.0

In 2.1.0 KMS log encryption is required by default. This requires that you create and attach a new AWS KMS key ARN.
As an example here is how to set that up (please review on your own):

```hcl
data "aws_iam_policy_document" "cloudwatch_logs_allow_kms" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }

    actions = [
      "kms:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Allow logs KMS access"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.us-west-2.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "main" {
  description         = "Key for ECS log encryption"
  enable_key_rotation = true

  policy = data.aws_iam_policy_document.cloudwatch_logs_allow_kms.json
}
```

**NOTE:** Best practice is to use a separate KMS key per ECS Service. Do not re-use KMS keys if it can be avoided.

### 1.15.0 to 2.0.0

v2.0.0 of this module is built against Terraform v0.12. In addition to
requiring this upgrade, the v1.15.0 version of the module took the name
of the ECS cluster as a parameter; v2.0.0 takes the actual object of the
ECS cluster as a parameter instead. You will need to update previous
instances of this module with the altered parameter.

## Developer Setup

Install dependencies (macOS)

```shell
brew install pre-commit go terraform terraform-docs
```

### Testing

[Terratest](https://github.com/gruntwork-io/terratest) is being used for
automated testing with this module. Tests in the `test` folder can be run
locally by running the following command:

```text
make test
```

Or with aws-vault:

```text
AWS_VAULT_KEYCHAIN_NAME=<NAME> aws-vault exec <PROFILE> -- make test
```
