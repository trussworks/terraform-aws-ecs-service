#
# ECS Service Module
#

module "app_ecs_service" {
  source = "../../"

  name        = var.ecs_service_name
  environment = "test"

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
