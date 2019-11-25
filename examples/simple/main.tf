
#
# KMS Key
#
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
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
  policy              = data.aws_iam_policy_document.cloudwatch_logs_allow_kms.json
}

#
# ECS Service Module
#

module "app_ecs_service" {
  source = "../../"

  name        = var.ecs_service_name
  environment = "test"

  kms_key_id = aws_kms_key.main.arn

  ecs_cluster    = aws_ecs_cluster.main
  ecs_vpc_id     = aws_vpc.main.id
  ecs_subnet_ids = [aws_subnet.main.id]
}

#
# ECS Cluster
#

resource "aws_ecs_cluster" "main" {
  name = var.ecs_service_name
}


#
# VPC
#

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Automation = "Terraform"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"

  tags = {
    Automation = "Terraform"
  }
}
