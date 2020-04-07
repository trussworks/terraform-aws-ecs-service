locals {
  environment                 = "test"
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

module "ecs-service" {
  source = "../../"

  name        = var.test_name
  environment = local.environment

  ecs_cluster      = aws_ecs_cluster.main
  ecs_subnet_ids   = module.vpc.public_subnets
  ecs_vpc_id       = module.vpc.vpc_id
  ecs_use_fargate  = true
  assign_public_ip = true
  additional_security_group_ids = [
    aws_security_group.ecs_allow_http.id
  ]

  hello_world_container_ports = local.hello_world_container_ports

  kms_key_id = aws_kms_key.main.arn
}

#
# Allow HTTP access to the ECS instance from the internet
#

resource "aws_security_group" "ecs_allow_http" {
  name        = "ecs-allow-http"
  description = "Allow inbound HTTP to the ECS instance"
  vpc_id      = module.vpc.vpc_id

}

resource "aws_security_group_rule" "ecs_allow_http" {
  count = length(local.hello_world_container_ports)

  security_group_id = aws_security_group.ecs_allow_http.id

  type        = "ingress"
  from_port   = element(local.hello_world_container_ports, count.index)
  to_port     = element(local.hello_world_container_ports, count.index)
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

