locals {
  environment                 = "test"
  protocol                    = var.associate_alb == true && var.associate_nlb == false ? "HTTP" : "TCP"
  hello_world_container_ports = [8080, 8081]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2"

  name = var.test_name
  cidr = "10.0.0.0/16"
  azs  = var.vpc_azs

  public_subnets = ["10.0.104.0/24", "10.0.105.0/24", "10.0.106.0/24"]

}

#
# KMS
#

data "aws_caller_identity" "current" {}

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
      identifiers = ["logs.${var.region}.amazonaws.com"]
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

#
# ECS Cluster
#

resource "aws_ecs_cluster" "main" {
  name = var.test_name
}

#
# ALB
#
resource "aws_lb" "main" {
  name               = var.test_name
  internal           = false
  load_balancer_type = var.associate_alb == true && var.associate_nlb == false ? "application" : "network"
  security_groups    = var.associate_alb == true && var.associate_nlb == false ? [aws_security_group.lb_sg.id] : null
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_listener" "http" {
  count = length(local.hello_world_container_ports)

  load_balancer_arn = aws_lb.main.id
  port              = element(local.hello_world_container_ports, count.index)
  protocol          = local.protocol

  default_action {
    target_group_arn = aws_lb_target_group.http[count.index].id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "http" {
  count = length(local.hello_world_container_ports)

  name     = "${var.test_name}-${local.hello_world_container_ports[count.index]}"
  port     = element(local.hello_world_container_ports, count.index)
  protocol = local.protocol

  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  deregistration_delay = 90

  health_check {
    timeout             = var.associate_alb == true && var.associate_nlb == false ? 5 : null
    interval            = 30
    path                = var.associate_alb == true && var.associate_nlb == false ? "/" : null
    protocol            = local.protocol
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = var.associate_alb == true && var.associate_nlb == false ? "200" : null
  }

  depends_on = [aws_lb.main]
}

resource "aws_security_group" "lb_sg" {
  name   = "lb-${var.test_name}"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "app_lb_allow_outbound" {
  security_group_id = aws_security_group.lb_sg.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_lb_allow_all_http" {
  count             = length(local.hello_world_container_ports)
  security_group_id = aws_security_group.lb_sg.id

  type        = "ingress"
  from_port   = element(local.hello_world_container_ports, count.index)
  to_port     = element(local.hello_world_container_ports, count.index)
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

#
# ECS Service
#
module "ecs-service" {
  source = "../../"

  name        = var.test_name
  environment = local.environment

  associate_alb = var.associate_alb
  associate_nlb = var.associate_nlb

  alb_security_group     = var.associate_alb == true && var.associate_nlb == false ? aws_security_group.lb_sg.id : null
  nlb_subnet_cidr_blocks = var.associate_alb == false && var.associate_nlb == true ? module.vpc.public_subnets_cidr_blocks : null

  hello_world_container_ports = local.hello_world_container_ports

  lb_target_groups = [
    {
      lb_target_group_arn         = aws_lb_target_group.http[0].arn
      container_port              = element(local.hello_world_container_ports, 0)
      container_health_check_port = element(local.hello_world_container_ports, 0)
    },
    {
      lb_target_group_arn         = aws_lb_target_group.http[1].arn
      container_port              = element(local.hello_world_container_ports, 0)
      container_health_check_port = element(local.hello_world_container_ports, 1)
    }
  ]

  ecs_cluster      = aws_ecs_cluster.main
  ecs_subnet_ids   = module.vpc.public_subnets
  ecs_vpc_id       = module.vpc.vpc_id
  ecs_use_fargate  = true
  assign_public_ip = true

  kms_key_id = aws_kms_key.main.arn
}
