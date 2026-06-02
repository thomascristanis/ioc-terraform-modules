locals {
  name = "${var.project_name}-${var.environment}"
}

resource "aws_ecs_cluster" "main" {
  name = local.name
  tags = var.tags

  setting {
    name  = "containerInsights"
    value = var.environment == "prd" ? "enabled" : "disabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
    base              = 0
  }
}
