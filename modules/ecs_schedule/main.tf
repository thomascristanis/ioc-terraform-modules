data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "scheduler_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  name               = "${var.project_name}-${var.environment}-ecs-scheduler"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "scheduler_ecs" {
  role = aws_iam_role.scheduler.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ecs:UpdateService"]
      Resource = "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${var.cluster_name}/${var.service_name}"
    }]
  })
}

resource "aws_scheduler_schedule" "stop" {
  name = "${var.project_name}-${var.environment}-ecs-stop"

  flexible_time_window { mode = "OFF" }
  schedule_expression          = var.stop_cron
  schedule_expression_timezone = "UTC"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ecs:updateService"
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      Cluster      = var.cluster_name
      Service      = var.service_name
      DesiredCount = var.scale_down_count
    })
  }
}

resource "aws_scheduler_schedule" "start" {
  name = "${var.project_name}-${var.environment}-ecs-start"

  flexible_time_window { mode = "OFF" }
  schedule_expression          = var.start_cron
  schedule_expression_timezone = "UTC"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ecs:updateService"
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      Cluster      = var.cluster_name
      Service      = var.service_name
      DesiredCount = var.scale_up_count
    })
  }
}
