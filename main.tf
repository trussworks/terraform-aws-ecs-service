/**
 * Creates an ECS service.
 *
 * Creates the following resources:
 *
 * * CloudWatch log group.
 * * Security Groups for the ECS service.
 * * ECS service.
 * * Task definition using `nginx:stable` (see below).
 *
 * We create an initial task definition using the `nginx:stable` image as a way
 * to validate the initial infrastructure is working: visiting the site shows
 * the Nginx welcome page. We expect deployments to manage the container
 * definitions going forward, not Terraform.
 *
 * ## Usage
 *
 * ```hcl
 * module "app_ecs_service" {
 *   source = "../../modules/aws-ecs-service"
 *
 *   name        = "app"
 *   environment = "prod"
 *
 *   ecs_cluster_arn               = "${module.app_ecs_cluster.ecs_cluster_arn}"
 *   ecs_vpc_id                    = "${module.vpc.vpc_id}"
 *   ecs_subnet_ids                = "${module.vpc.private_subnets}"
 *   tasks_desired_count           = 2
 *   tasks_minimum_healthy_percent = 50
 *   tasks_maximum_percent         = 200
 *
 *   alb_security_group = "${module.security_group.id}"
 *   alb_target_group   = "${module.target_group.id}"
 * }
 * ```
 */

locals {
  awslogs_group = "ecs-tasks-${var.name}-${var.environment}"
}

#
# CloudWatch
#

resource "aws_cloudwatch_log_group" "main" {
  name              = "${local.awslogs_group}"
  retention_in_days = "${var.logs_cloudwatch_retention}"

  tags {
    Name        = "${var.name}-${var.environment}"
    Environment = "${var.environment}"
  }
}

#
# SG - ECS
#

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-${var.name}-${var.environment}"
  description = "${var.name}-${var.environment} container security group"
  vpc_id      = "${var.ecs_vpc_id}"

  tags = {
    Environment = "${var.environment}"
  }
}

resource "aws_security_group_rule" "app_ecs_allow_outbound" {
  description       = "All outbound"
  security_group_id = "${aws_security_group.ecs_sg.id}"

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_ecs_allow_https_from_alb" {
  description       = "Allow in ALB"
  security_group_id = "${aws_security_group.ecs_sg.id}"

  type                     = "ingress"
  from_port                = "${var.container_port}"
  to_port                  = "${var.container_port}"
  protocol                 = "tcp"
  source_security_group_id = "${var.alb_security_group}"
}

#
# IAM
#

data "aws_iam_policy_document" "task_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_role" {
  name               = "ecs-task-role-${var.name}-${var.environment}"
  assume_role_policy = "${data.aws_iam_policy_document.task_role_assume_role_policy.json}"
}

#
# ECS
#

data "aws_region" "current" {}

# Create a task definition with an Nginx image so the ecs service can be easily
# tested. We expect deployments will manage the future container definitions.
resource "aws_ecs_task_definition" "main" {
  family        = "${var.name}-${var.environment}"
  network_mode  = "awsvpc"
  task_role_arn = "${aws_iam_role.task_role.arn}"

  container_definitions = <<EOF
[
  {
    "name": "${var.name}-${var.environment}",
    "image": "nginx:stable",
    "cpu": 128,
    "memory": 128,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${local.awslogs_group}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "nginx"
      }
    },
    "environment": [],
    "mountPoints": [],
    "volumesFrom": []
  }
]
EOF
}

# Create a data source to pull the latest active revision from
data "aws_ecs_task_definition" "main" {
  task_definition = "${aws_ecs_task_definition.main.family}"
  depends_on      = ["aws_ecs_task_definition.main"]         # ensures at least one task def exists
}

resource "aws_ecs_service" "main" {
  name    = "${var.name}"
  cluster = "${var.ecs_cluster_arn}"

  # Use latest active revision
  task_definition = "${aws_ecs_task_definition.main.family}:${max(
    "${aws_ecs_task_definition.main.revision}",
    "${data.aws_ecs_task_definition.main.revision}")}"

  desired_count                      = "${var.tasks_desired_count}"
  deployment_minimum_healthy_percent = "${var.tasks_minimum_healthy_percent}"
  deployment_maximum_percent         = "${var.tasks_maximum_percent}"

  placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  placement_strategy {
    type  = "spread"
    field = "instanceId"
  }

  placement_constraints {
    type = "distinctInstance"
  }

  network_configuration {
    subnets          = ["${var.ecs_subnet_ids}"]
    security_groups  = ["${aws_security_group.ecs_sg.id}"]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = "${var.alb_target_group}"
    container_name   = "${aws_ecs_task_definition.main.family}"
    container_port   = "${var.container_port}"
  }

  lifecycle {
    ignore_changes = ["task_definition"]
  }
}
