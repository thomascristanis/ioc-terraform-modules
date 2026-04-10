locals {
  name       = "${var.project_name}-${var.environment}"
  has_cert   = var.certificate_arn != ""
  subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : var.public_subnet_ids
}

# --- Security Group ---

resource "aws_security_group" "alb" {
  name        = "${local.name}-alb"
  description = "Allow HTTP/HTTPS inbound traffic to ALB"
  vpc_id      = var.vpc_id
  tags        = var.tags

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- ALB ---

resource "aws_lb" "main" {
  name               = substr("${local.name}-alb", 0, 32)
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.subnet_ids
  tags               = var.tags

  lifecycle {
    precondition {
      condition     = length(local.subnet_ids) >= 2
      error_message = "Provide at least 2 subnet IDs using subnet_ids (preferred) or public_subnet_ids (deprecated)."
    }
  }
}

# --- HTTP Listener ---
# Redirects to HTTPS when a certificate is provided, forwards directly otherwise (dev without cert)

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  tags              = var.tags

  default_action {
    type = local.has_cert ? "redirect" : "fixed-response"

    dynamic "redirect" {
      for_each = local.has_cert ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "fixed_response" {
      for_each = local.has_cert ? [] : [1]
      content {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
      }
    }
  }
}

# --- HTTPS Listener (only when certificate_arn is provided) ---

resource "aws_lb_listener" "https" {
  count             = local.has_cert ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn
  tags              = var.tags

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}
