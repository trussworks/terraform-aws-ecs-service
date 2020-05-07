locals {
  awslogs_group         = "${var.logs_cloudwatch_group == "" ? "/ecs/${var.environment}/${var.name}" : var.logs_cloudwatch_group}"
  target_container_name = "${var.target_container_name == "" ? "${var.name}-${var.environment}" : var.target_container_name}"
  cloudwatch_alarm_name = "${var.cloudwatch_alarm_name == "" ? "${var.name}-${var.environment}" : var.cloudwatch_alarm_name}"

  # for each target group, allow ingress from the alb to ecs container port
  lb_ingress_container_ports = distinct(
    [
      for lb_target_group in var.lb_target_groups : lb_target_group.container_port
    ]
  )

  # for each target group, allow ingress from the alb to ecs healthcheck port
  # if it doesn't collide with the container ports
  lb_ingress_container_health_check_ports = tolist(
    setsubtract(
      [
        for lb_target_group in var.lb_target_groups : lb_target_group.container_health_check_port
      ],
      local.lb_ingress_container_ports,
    )
  )

  # base64 encoded version of the helloworld go app
  base64_encode_helloworld = base64encode(file("${path.module}/examples/helloworld.go"))

  # default container definition to be used with the helloworld go app included
  # in this repo. It currently supports 2 HTTP listeners configured on
  # environment variables PORT1 and PORT2 and simple JSON requests logs
  default_container_definitions = jsonencode(
    [

      {
        name  = local.target_container_name
        image = var.container_image

        cpu       = var.fargate_task_cpu
        memory    = var.fargate_task_memory
        essential = true

        portMappings = [
          {
            containerPort = element(var.hello_world_container_ports, 0)
            hostPort      = element(var.hello_world_container_ports, 0)
            protocol      = "tcp"
          },
          {
            containerPort = element(var.hello_world_container_ports, 1)
            hostPort      = element(var.hello_world_container_ports, 1)
            protocol      = "tcp"
          }
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = local.awslogs_group
            "awslogs-region"        = data.aws_region.current.name
            "awslogs-stream-prefix" = "helloworld"
          }
        }
        environment = [
          {
            "name" : "PORT1",
            "value" : tostring(element(var.hello_world_container_ports, 0))
          },
          {
            "name" : "PORT2",
            "value" : tostring(element(var.hello_world_container_ports, 1))
          }
        ]
        mountPoints = []
        volumesFrom = []
        entryPoint = [
          "/bin/sh", "-c",
          "echo '${local.base64_encode_helloworld}' | base64 -d > helloworld.go && go run helloworld.go"
        ]

      }
    ]
  )
}



#
# CloudWatch
#

resource "aws_cloudwatch_log_group" "main" {
  name              = local.awslogs_group
  retention_in_days = var.logs_cloudwatch_retention

  kms_key_id = var.kms_key_id

  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
    Automation  = "Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_cpu" {
  count = var.cloudwatch_alarm_cpu_enable && (var.associate_alb || var.associate_nlb) ? 1 : 0

  alarm_name        = "${local.cloudwatch_alarm_name}-cpu"
  alarm_description = "Monitors ECS CPU Utilization"
  alarm_actions     = var.cloudwatch_alarm_actions

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.cloudwatch_alarm_cpu_threshold

  dimensions = {
    "ClusterName" = var.ecs_cluster.name
    "ServiceName" = aws_ecs_service.main[count.index].name
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_mem" {
  count = var.cloudwatch_alarm_cpu_enable && (var.associate_alb || var.associate_nlb) ? 1 : 0

  alarm_name        = "${local.cloudwatch_alarm_name}-mem"
  alarm_description = "Monitors ECS CPU Utilization"
  alarm_actions     = var.cloudwatch_alarm_actions

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.cloudwatch_alarm_mem_threshold

  dimensions = {
    "ClusterName" = var.ecs_cluster.name
    "ServiceName" = aws_ecs_service.main[count.index].name
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_cpu_no_lb" {
  count = var.cloudwatch_alarm_cpu_enable && ! (var.associate_alb || var.associate_nlb) ? 1 : 0

  alarm_name        = "${local.cloudwatch_alarm_name}-cpu"
  alarm_description = "Monitors ECS CPU Utilization"
  alarm_actions     = var.cloudwatch_alarm_actions

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.cloudwatch_alarm_cpu_threshold

  dimensions = {
    "ClusterName" = var.ecs_cluster.name
    "ServiceName" = aws_ecs_service.main_no_lb[count.index].name
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_mem_no_lb" {
  count = var.cloudwatch_alarm_cpu_enable && ! (var.associate_alb || var.associate_nlb) ? 1 : 0

  alarm_name        = "${local.cloudwatch_alarm_name}-mem"
  alarm_description = "Monitors ECS CPU Utilization"
  alarm_actions     = var.cloudwatch_alarm_actions

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.cloudwatch_alarm_mem_threshold

  dimensions = {
    "ClusterName" = var.ecs_cluster.name
    "ServiceName" = aws_ecs_service.main_no_lb[count.index].name
  }
}

#
# SG - ECS
#

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-${var.name}-${var.environment}"
  description = "${var.name}-${var.environment} container security group"
  vpc_id      = var.ecs_vpc_id

  tags = {
    Name        = "ecs-${var.name}-${var.environment}"
    Environment = var.environment
    Automation  = "Terraform"
  }
}

resource "aws_security_group_rule" "app_ecs_allow_outbound" {
  description       = "All outbound"
  security_group_id = aws_security_group.ecs_sg.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_ecs_allow_https_from_alb" {
  # if we have an alb, then create security group rules for the container
  # ports
  count = var.associate_alb ? length(local.lb_ingress_container_ports) : 0

  description       = "Allow in ALB"
  security_group_id = aws_security_group.ecs_sg.id

  type                     = "ingress"
  from_port                = element(local.lb_ingress_container_ports, count.index)
  to_port                  = element(local.lb_ingress_container_ports, count.index)
  protocol                 = "tcp"
  source_security_group_id = var.alb_security_group
}

resource "aws_security_group_rule" "app_ecs_allow_health_check_from_alb" {
  # if we have an alb, then create security group rules for the container
  # health check ports
  count = var.associate_alb ? length(local.lb_ingress_container_health_check_ports) : 0

  description       = "Allow in health check from ALB"
  security_group_id = aws_security_group.ecs_sg.id

  type                     = "ingress"
  from_port                = element(local.lb_ingress_container_health_check_ports, count.index)
  to_port                  = element(local.lb_ingress_container_health_check_ports, count.index)
  protocol                 = "tcp"
  source_security_group_id = var.alb_security_group
}

resource "aws_security_group_rule" "app_ecs_allow_tcp_from_nlb" {
  count = var.associate_nlb ? length(local.lb_ingress_container_ports) : 0

  description       = "Allow in NLB"
  security_group_id = aws_security_group.ecs_sg.id

  type        = "ingress"
  from_port   = element(local.lb_ingress_container_ports, count.index)
  to_port     = element(local.lb_ingress_container_ports, count.index)
  protocol    = "tcp"
  cidr_blocks = var.nlb_subnet_cidr_blocks
}

resource "aws_security_group_rule" "app_ecs_allow_health_check_from_nlb" {
  count = var.associate_nlb ? length(local.lb_ingress_container_health_check_ports) : 0

  description       = "Allow in health check from NLB"
  security_group_id = aws_security_group.ecs_sg.id

  type        = "ingress"
  from_port   = element(local.lb_ingress_container_health_check_ports, count.index)
  to_port     = element(local.lb_ingress_container_health_check_ports, count.index)
  protocol    = "tcp"
  cidr_blocks = var.nlb_subnet_cidr_blocks
}

#
# IAM - instance (optional)
#

data "aws_iam_policy_document" "instance_role_policy_doc" {
  count = var.ecs_instance_role != "" ? 1 : 0

  statement {
    actions = [
      "ecs:DeregisterContainerInstance",
      "ecs:RegisterContainerInstance",
      "ecs:Submit*",
    ]

    resources = [var.ecs_cluster.arn]
  }

  statement {
    actions = [
      "ecs:UpdateContainerInstancesState",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ecs:cluster"
      values   = [var.ecs_cluster.arn]
    }
  }

  statement {
    actions = [
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:StartTelemetrySession",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [aws_cloudwatch_log_group.main.arn]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]

    resources = var.ecr_repo_arns
  }
}

resource "aws_iam_role_policy" "instance_role_policy" {
  count = var.ecs_instance_role != "" ? 1 : 0

  name   = "${var.ecs_instance_role}-policy"
  role   = var.ecs_instance_role
  policy = data.aws_iam_policy_document.instance_role_policy_doc[0].json
}

#
# IAM - task
#

data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task_execution_role_policy_doc" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [aws_cloudwatch_log_group.main.arn]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]

    resources = var.ecr_repo_arns
  }
}

resource "aws_iam_role" "task_role" {
  name               = "ecs-task-role-${var.name}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role" "task_execution_role" {
  count = var.ecs_use_fargate ? 1 : 0

  name               = "ecs-task-execution-role-${var.name}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role_policy" "task_execution_role_policy" {
  count = var.ecs_use_fargate ? 1 : 0

  name   = "${aws_iam_role.task_execution_role[0].name}-policy"
  role   = aws_iam_role.task_execution_role[0].name
  policy = data.aws_iam_policy_document.task_execution_role_policy_doc.json
}

#
# ECS
#

data "aws_region" "current" {
}

# Create a task definition with a golang image so the ecs service can be easily
# tested. We expect deployments will manage the future container definitions.
resource "aws_ecs_task_definition" "main" {
  family        = "${var.name}-${var.environment}"
  network_mode  = "awsvpc"
  task_role_arn = aws_iam_role.task_role.arn

  # Fargate requirements
  requires_compatibilities = compact([var.ecs_use_fargate ? "FARGATE" : ""])
  cpu                      = var.ecs_use_fargate ? var.fargate_task_cpu : ""
  memory                   = var.ecs_use_fargate ? var.fargate_task_memory : ""
  execution_role_arn       = join("", aws_iam_role.task_execution_role.*.arn)

  container_definitions = var.container_definitions == "" ? local.default_container_definitions : var.container_definitions

  lifecycle {
    ignore_changes = [
      requires_compatibilities,
      cpu,
      memory,
      execution_role_arn,
      container_definitions,
    ]
  }
}

# Create a data source to pull the latest active revision from
data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.main.family
  depends_on      = [aws_ecs_task_definition.main] # ensures at least one task def exists
}

locals {
  ecs_service_launch_type = var.ecs_use_fargate ? "FARGATE" : "EC2"

  ecs_service_ordered_placement_strategy = {
    EC2 = [
      {
        type  = "spread"
        field = "attribute:ecs.availability-zone"
      },
      {
        type  = "spread"
        field = "instanceId"
      },
    ]
    FARGATE = []
  }

  ecs_service_placement_constraints = {
    EC2 = [
      {
        type = "distinctInstance"
      },
    ]
    FARGATE = []
  }

  ecs_service_agg_security_groups = compact(concat(list(aws_security_group.ecs_sg.id), var.additional_security_group_ids))
}

resource "aws_ecs_service" "main" {
  count = var.associate_alb || var.associate_nlb ? 1 : 0

  name    = var.name
  cluster = var.ecs_cluster.arn

  launch_type = local.ecs_service_launch_type

  # Use latest active revision
  task_definition = "${aws_ecs_task_definition.main.family}:${max(
    aws_ecs_task_definition.main.revision,
    data.aws_ecs_task_definition.main.revision,
  )}"

  desired_count                      = var.tasks_desired_count
  deployment_minimum_healthy_percent = var.tasks_minimum_healthy_percent
  deployment_maximum_percent         = var.tasks_maximum_percent

  dynamic ordered_placement_strategy {
    for_each = local.ecs_service_ordered_placement_strategy[local.ecs_service_launch_type]

    content {
      type  = ordered_placement_strategy.value.type
      field = ordered_placement_strategy.value.field
    }
  }

  dynamic placement_constraints {
    for_each = local.ecs_service_placement_constraints[local.ecs_service_launch_type]

    content {
      type = placement_constraints.value.type
    }
  }

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = local.ecs_service_agg_security_groups
    assign_public_ip = var.assign_public_ip
  }

  dynamic load_balancer {
    for_each = var.lb_target_groups
    content {
      container_name   = local.target_container_name
      target_group_arn = load_balancer.value.lb_target_group_arn
      container_port   = load_balancer.value.container_port
    }
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

# NOTE: We have to duplicate this resource with a count instead of parameterizing
# the load_balancer argument due to this Terraform bug:
# https://github.com/hashicorp/terraform/issues/16856
resource "aws_ecs_service" "main_no_lb" {
  count = var.associate_alb || var.associate_nlb ? 0 : 1

  name    = var.name
  cluster = var.ecs_cluster.arn

  launch_type = local.ecs_service_launch_type

  # Use latest active revision
  task_definition = "${aws_ecs_task_definition.main.family}:${max(
    aws_ecs_task_definition.main.revision,
    data.aws_ecs_task_definition.main.revision,
  )}"

  desired_count                      = var.tasks_desired_count
  deployment_minimum_healthy_percent = var.tasks_minimum_healthy_percent
  deployment_maximum_percent         = var.tasks_maximum_percent

  dynamic ordered_placement_strategy {
    for_each = local.ecs_service_ordered_placement_strategy[local.ecs_service_launch_type]
    #    for_each = var.ecs_use_fargate ? [] : ["attribute:ecs.availability-zone", "instanceId"]

    content {
      type  = ordered_placement_strategy.value.type
      field = ordered_placement_strategy.value.field
    }
  }

  dynamic placement_constraints {
    for_each = local.ecs_service_placement_constraints[local.ecs_service_launch_type]
    #    for_each = var.ecs_use_fargate ? [] : ["distinctInstance"]

    content {
      type = placement_constraints.value.type
    }
  }

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = local.ecs_service_agg_security_groups
    assign_public_ip = var.assign_public_ip
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}
