locals {
  name = "${var.project_name}-${var.environment}"
}

# --- IAM ---

data "aws_iam_policy_document" "task_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${local.name}-task-execution"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "task_execution_basic" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name               = "${local.name}-task"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  tags               = var.tags
}

# DynamoDB access for the task role
resource "aws_iam_role_policy" "task_dynamodb" {
  name = "${local.name}-dynamodb"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = ["arn:aws:dynamodb:${var.aws_region}:*:table/${var.project_name}_${var.environment}_*"]
      }
    ]
  })
}

# --- CloudWatch Log Group ---

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# --- Security Group ---

resource "aws_security_group" "app" {
  name        = "${local.name}-app"
  description = "Allow traffic from ALB to app container"
  vpc_id      = var.vpc_id
  tags        = var.tags

  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Task Definition ---

resource "aws_ecs_task_definition" "app" {
  family                   = local.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn
  tags                     = var.tags

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.app_port
          protocol      = "tcp"
        }
      ]

      environment = [
        for k, v in var.environment_variables : { name = k, value = v }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# --- ALB Target Group ---

resource "aws_lb_target_group" "app" {
  name        = substr("${local.name}-tg", 0, 32)
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  tags        = var.tags

  health_check {
    path                = var.health_check_path
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener_rule" "app" {
  listener_arn = var.alb_listener_arn
  priority     = var.alb_listener_priority
  tags         = var.tags

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# --- ECS Service ---

resource "aws_ecs_service" "app" {
  name                              = local.name
  cluster                           = var.cluster_arn
  task_definition                   = aws_ecs_task_definition.app.arn
  desired_count                     = 1
  health_check_grace_period_seconds = var.health_check_grace_period_seconds
  tags                              = var.tags

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = var.app_port
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
    base              = var.use_spot_only ? 1 : 0
  }

  dynamic "capacity_provider_strategy" {
    for_each = var.use_spot_only ? [] : [1]
    content {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 0
    }
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}
