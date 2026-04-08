# Terraform Best Practices Review — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply security, reliability, and code quality best practices across all 9 Terraform modules in three risk-tiered layers.

**Architecture:** Changes are grouped by risk level — non-destructive first (Layer 1), controlled destroy/recreate second (Layer 2), new features third (Layer 3). Each task ends with `terraform validate` + `terraform fmt` before committing.

**Tech Stack:** Terraform >= 1.3, AWS Provider ~> 5.0, HCL

---

## Validation commands (reference for all tasks)

```bash
# After every change in a module:
cd modules/<module>
terraform init -backend=false
terraform validate
terraform fmt -check
```

If `fmt -check` fails, run `terraform fmt` then re-check.

---

## LAYER 1 — Zero risk

---

### Task 1: Add `versions.tf` to all 9 modules

**Files:**
- Create: `modules/api_gateway/versions.tf`
- Create: `modules/budget/versions.tf`
- Create: `modules/cloudfront/versions.tf`
- Create: `modules/cognito/versions.tf`
- Create: `modules/dynamodb/versions.tf`
- Create: `modules/ecr/versions.tf`
- Create: `modules/ecs/versions.tf`
- Create: `modules/ecs_schedule/versions.tf`
- Create: `modules/nat_instance/versions.tf`

- [ ] **Step 1: Create `versions.tf` in all 9 modules** (same content for each)

```hcl
terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

- [ ] **Step 2: Validate each module**

```bash
for m in api_gateway budget cloudfront cognito dynamodb ecr ecs ecs_schedule nat_instance; do
  echo "--- $m ---"
  cd modules/$m && terraform init -backend=false -no-color 2>&1 | tail -1 && terraform validate && cd ../..
done
```

Expected: `Success! The configuration is valid.` for each module.

- [ ] **Step 3: Commit**

```bash
git add modules/*/versions.tf
git commit -m "chore: add versions.tf with provider constraints to all modules"
```

---

### Task 2: Add `tags` variable and apply to all modules

**Files:**
- Modify: `modules/api_gateway/variables.tf`, `modules/api_gateway/main.tf`
- Modify: `modules/cloudfront/variables.tf`, `modules/cloudfront/main.tf`
- Modify: `modules/cognito/variables.tf`, `modules/cognito/main.tf`
- Modify: `modules/dynamodb/variables.tf`, `modules/dynamodb/main.tf`
- Modify: `modules/ecr/variables.tf`, `modules/ecr/main.tf`
- Modify: `modules/ecs/variables.tf`, `modules/ecs/main.tf`
- Modify: `modules/ecs_schedule/variables.tf`, `modules/ecs_schedule/main.tf`
- Modify: `modules/nat_instance/variables.tf`, `modules/nat_instance/main.tf`

Note: `budget` is excluded — `aws_budgets_budget` does not support tags in the AWS provider.

- [ ] **Step 1: Add `tags` variable to each `variables.tf`**

Add the following block to the end of each affected `variables.tf`:

```hcl
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

- [ ] **Step 2: Apply tags in `modules/dynamodb/main.tf`**

Add `tags = var.tags` to all 8 `aws_dynamodb_table` resources. Example for `users`:

```hcl
resource "aws_dynamodb_table" "users" {
  name         = "${local.prefix}_users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  tags         = var.tags
  # ... rest unchanged
}
```

Repeat for: `books`, `subscriptions`, `spaces`, `catalog`, `tracker`, `library_access`, `rate_limits`.

- [ ] **Step 3: Apply tags in `modules/ecr/main.tf`**

```hcl
resource "aws_ecr_repository" "backend" {
  name                 = "${var.project_name}-${var.environment}-backend"
  image_tag_mutability = "MUTABLE"
  tags                 = var.tags

  image_scanning_configuration {
    scan_on_push = true
  }
}
```

- [ ] **Step 4: Apply tags in `modules/cognito/main.tf`**

```hcl
resource "aws_cognito_user_pool" "main" {
  name = local.name
  tags = var.tags
  # ... rest unchanged
}
```

- [ ] **Step 5: Apply tags in `modules/ecs/main.tf`**

Add `tags = var.tags` to:
- `aws_iam_role.task_execution`
- `aws_iam_role.task`
- `aws_cloudwatch_log_group.app`
- `aws_security_group.app`
- `aws_ecs_task_definition.app`
- `aws_lb_target_group.app`
- `aws_ecs_service.app`

Example:
```hcl
resource "aws_iam_role" "task_execution" {
  name               = "${local.name}-task-execution"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  tags               = var.tags
}
```

- [ ] **Step 6: Apply tags in `modules/api_gateway/main.tf`**

Add `tags = var.tags` to:
- `aws_apigatewayv2_api.main`
- `aws_apigatewayv2_vpc_link.main`
- `aws_apigatewayv2_stage.default`

- [ ] **Step 7: Apply tags in `modules/cloudfront/main.tf`**

Add `tags = var.tags` to:
- `aws_s3_bucket.frontend`
- `aws_cloudfront_distribution.frontend`

- [ ] **Step 8: Apply tags in `modules/ecs_schedule/main.tf`**

Add `tags = var.tags` to `aws_iam_role.scheduler`.

- [ ] **Step 9: Apply tags in `modules/nat_instance/main.tf`**

Replace the hardcoded `tags` on `aws_instance.nat` with `merge`:
```hcl
resource "aws_instance" "nat" {
  # ... unchanged fields ...
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-nat"
  })
}
```

Add `tags = var.tags` to `aws_security_group.nat`.

- [ ] **Step 10: Validate all modified modules**

```bash
for m in api_gateway cloudfront cognito dynamodb ecr ecs ecs_schedule nat_instance; do
  echo "--- $m ---"
  cd modules/$m && terraform validate && terraform fmt -check && cd ../..
done
```

- [ ] **Step 11: Commit**

```bash
git add modules/
git commit -m "feat: add tags variable and apply to all taggable resources"
```

---

### Task 3: Fix variable descriptions

**Files:**
- Modify: `modules/ecr/variables.tf`
- Modify: `modules/ecs/variables.tf`
- Modify: `modules/nat_instance/variables.tf`
- Modify: `modules/cloudfront/variables.tf`
- Modify: `modules/dynamodb/variables.tf`

- [ ] **Step 1: Replace `modules/ecr/variables.tf`**

```hcl
variable "project_name" {
  description = "Project name used as a prefix for all resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)."
  type        = string
}

variable "image_count_to_keep" {
  description = "Number of most recent images to retain in ECR lifecycle policy."
  type        = number
  default     = 3
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

- [ ] **Step 2: Replace `modules/ecs/variables.tf`**

```hcl
variable "project_name" {
  description = "Project name used as a prefix for all resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)."
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster to deploy the service into."
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster (used for CloudWatch and IAM scoping)."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the ECS service network configuration."
  type        = list(string)
}

variable "alb_listener_arn" {
  description = "ARN of the ALB HTTPS listener to attach the target group rule to."
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB, used to allow ingress from ALB to the app."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ECS service and security groups are created."
  type        = string
}

variable "container_image" {
  description = "Full container image URI (e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com/app:latest)."
  type        = string
}

variable "app_port" {
  description = "Port the container listens on."
  type        = number
}

variable "aws_region" {
  description = "AWS region for CloudWatch log group and IAM DynamoDB policy."
  type        = string
}

variable "cpu" {
  description = "Fargate task CPU units (256, 512, 1024, 2048, 4096)."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory in MB."
  type        = number
  default     = 512
}

variable "use_spot_only" {
  description = "true = pure FARGATE_SPOT (dev); false = SPOT + on-demand fallback (prod)."
  type        = bool
  default     = false
}

variable "environment_variables" {
  description = "Container environment variables passed as key-value pairs."
  type        = map(string)
  default     = {}
}

variable "health_check_path" {
  description = "ALB health check path for the target group."
  type        = string
  default     = "/health"
}

variable "alb_listener_priority" {
  description = "Priority for the ALB listener rule (1-50000, lower = higher priority)."
  type        = number
  default     = 100
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days."
  type        = number
  default     = 7
}

variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore failing ALB health checks after a new task starts (boot time)."
  type        = number
  default     = 60
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
```

- [ ] **Step 3: Replace `modules/nat_instance/variables.tf`**

```hcl
variable "project_name" {
  description = "Project name used as a prefix for all resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the NAT instance and security group are created."
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet where the NAT instance is launched."
  type        = string
}

variable "private_route_table_id" {
  description = "ID of the private route table to update with the NAT instance as the default gateway."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
```

- [ ] **Step 4: Replace `modules/cloudfront/variables.tf`**

```hcl
variable "project_name" {
  description = "Project name used as a prefix for all resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)."
  type        = string
}

variable "price_class" {
  description = "CloudFront price class (PriceClass_100 = US/Canada/Europe, PriceClass_200 adds Asia/ME/Africa, PriceClass_All = global)."
  type        = string
  default     = "PriceClass_100"
}

variable "aliases" {
  description = "Custom domain aliases for the CloudFront distribution. Requires acm_certificate_arn."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for custom domain TLS (must be in us-east-1). Required when aliases is non-empty."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
```

- [ ] **Step 5: Standardise `modules/dynamodb/variables.tf`** (fix `type`-before-`description` order)

```hcl
variable "project_name" {
  description = "Project name used as a prefix for all DynamoDB table names."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
```

- [ ] **Step 6: Validate**

```bash
for m in ecr ecs nat_instance cloudfront dynamodb; do
  echo "--- $m ---"
  cd modules/$m && terraform validate && terraform fmt -check && cd ../..
done
```

- [ ] **Step 7: Commit**

```bash
git add modules/ecr/variables.tf modules/ecs/variables.tf modules/nat_instance/variables.tf modules/cloudfront/variables.tf modules/dynamodb/variables.tf
git commit -m "docs: add variable descriptions and standardise variable format"
```

---

### Task 4: Parameterize hardcoded values

**Files:**
- Modify: `modules/ecs/main.tf`
- Modify: `modules/ecs_schedule/variables.tf`, `modules/ecs_schedule/main.tf`
- Modify: `modules/cloudfront/main.tf`

Note: `modules/ecs/variables.tf` was fully rewritten in Task 3 — the new variables (`health_check_path`, `alb_listener_priority`, `log_retention_days`, `health_check_grace_period_seconds`) are already declared there.

- [ ] **Step 1: Update `modules/ecs/main.tf` to use new variables**

Replace the `aws_cloudwatch_log_group` block:
```hcl
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}
```

Replace the health check `path` in `aws_lb_target_group`:
```hcl
health_check {
  path                = var.health_check_path
  interval            = 30
  timeout             = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}
```

Replace the `priority` in `aws_lb_listener_rule`:
```hcl
resource "aws_lb_listener_rule" "app" {
  listener_arn = var.alb_listener_arn
  priority     = var.alb_listener_priority
  # ... rest unchanged
}
```

Add `health_check_grace_period_seconds` to `aws_ecs_service`:
```hcl
resource "aws_ecs_service" "app" {
  name                               = local.name
  cluster                            = var.cluster_arn
  task_definition                    = aws_ecs_task_definition.app.arn
  desired_count                      = 1
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  # ... rest unchanged
}
```

- [ ] **Step 2: Add cron and count variables to `modules/ecs_schedule/variables.tf`**

Append to the file:
```hcl
variable "stop_cron" {
  description = "EventBridge cron expression for stopping the service (UTC). Default: 22:00 UTC (19:00 BRT)."
  type        = string
  default     = "cron(0 22 * * ? *)"
}

variable "start_cron" {
  description = "EventBridge cron expression for starting the service (UTC). Default: 08:00 UTC (05:00 BRT)."
  type        = string
  default     = "cron(0 8 * * ? *)"
}

variable "scale_down_count" {
  description = "Desired task count when stopping the service (typically 0)."
  type        = number
  default     = 0
}

variable "scale_up_count" {
  description = "Desired task count when starting the service."
  type        = number
  default     = 1
}
```

- [ ] **Step 3: Update `modules/ecs_schedule/main.tf` to use new variables**

Replace `schedule_expression` and `input` in both schedule resources:

```hcl
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
```

- [ ] **Step 4: Update `modules/cloudfront/main.tf` to use `var.price_class`**

Replace the hardcoded value:
```hcl
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = var.price_class
  # ... rest unchanged
}
```

- [ ] **Step 5: Validate**

```bash
for m in ecs ecs_schedule cloudfront; do
  echo "--- $m ---"
  cd modules/$m && terraform validate && terraform fmt -check && cd ../..
done
```

- [ ] **Step 6: Commit**

```bash
git add modules/ecs/main.tf modules/ecs_schedule/variables.tf modules/ecs_schedule/main.tf modules/cloudfront/main.tf
git commit -m "refactor: parameterize hardcoded values in ecs, ecs_schedule, cloudfront"
```

---

## LAYER 2 — Destrutivo controlado

---

### Task 5: DynamoDB — PITR and SSE on all 8 tables

**Files:**
- Modify: `modules/dynamodb/main.tf`

- [ ] **Step 1: Add PITR and SSE blocks to each table**

Add the following two blocks to every `aws_dynamodb_table` resource in `modules/dynamodb/main.tf`. Repeat for all 8 tables (`users`, `books`, `subscriptions`, `spaces`, `catalog`, `tracker`, `library_access`, `rate_limits`):

```hcl
point_in_time_recovery {
  enabled = true
}

server_side_encryption {
  enabled = true
}
```

Example — `users` table after change:
```hcl
resource "aws_dynamodb_table" "users" {
  name         = "${local.prefix}_users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  tags         = var.tags

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "apid"
    type = "S"
  }

  global_secondary_index {
    name            = "auth-provider-index"
    projection_type = "KEYS_ONLY"

    key_schema {
      attribute_name = "apid"
      key_type       = "HASH"
    }
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }
}
```

- [ ] **Step 2: Validate**

```bash
cd modules/dynamodb && terraform validate && terraform fmt -check && cd ../..
```

- [ ] **Step 3: Commit**

```bash
git add modules/dynamodb/main.tf
git commit -m "feat: enable PITR and explicit SSE on all DynamoDB tables"
```

---

### Task 6: ECR — immutable tags and explicit encryption

**Files:**
- Modify: `modules/ecr/main.tf`

- [ ] **Step 1: Update `modules/ecr/main.tf`**

```hcl
resource "aws_ecr_repository" "backend" {
  name                 = "${var.project_name}-${var.environment}-backend"
  image_tag_mutability = var.environment == "prod" ? "IMMUTABLE" : "MUTABLE"
  tags                 = var.tags

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}
```

- [ ] **Step 2: Validate**

```bash
cd modules/ecr && terraform validate && terraform fmt -check && cd ../..
```

- [ ] **Step 3: Commit**

```bash
git add modules/ecr/main.tf
git commit -m "feat: immutable image tags in prod and explicit AES256 encryption in ECR"
```

---

### Task 7: NAT instance — Elastic IP

**Files:**
- Modify: `modules/nat_instance/main.tf`

- [ ] **Step 1: Add EIP and association to `modules/nat_instance/main.tf`**

Add after the `aws_instance.nat` resource:

```hcl
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  })
}

resource "aws_eip_association" "nat" {
  instance_id   = aws_instance.nat.id
  allocation_id = aws_eip.nat.id
}
```

- [ ] **Step 2: Add EIP public IP to outputs**

In `modules/nat_instance/outputs.tf`, add:

```hcl
output "nat_public_ip" {
  description = "Elastic IP address of the NAT instance."
  value       = aws_eip.nat.public_ip
}
```

- [ ] **Step 3: Validate**

```bash
cd modules/nat_instance && terraform validate && terraform fmt -check && cd ../..
```

- [ ] **Step 4: Commit**

```bash
git add modules/nat_instance/main.tf modules/nat_instance/outputs.tf
git commit -m "feat: add Elastic IP to NAT instance for stable public IP"
```

---

## LAYER 3 — Novas features

---

### Task 8: Budget — FORECASTED alert

**Files:**
- Modify: `modules/budget/main.tf`

- [ ] **Step 1: Add forecasted notification block to `modules/budget/main.tf`**

Add a third `notification` block after the existing two:

```hcl
notification {
  comparison_operator        = "GREATER_THAN"
  threshold                  = 100
  threshold_type             = "PERCENTAGE"
  notification_type          = "FORECASTED"
  subscriber_email_addresses = [var.alert_email]
}
```

Full resource after change:
```hcl
resource "aws_budgets_budget" "daily" {
  name         = "${var.project_name}-${var.environment}-daily"
  budget_type  = "COST"
  limit_amount = tostring(var.daily_limit_usd)
  limit_unit   = "USD"
  time_unit    = "DAILY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}
```

- [ ] **Step 2: Validate**

```bash
cd modules/budget && terraform validate && terraform fmt -check && cd ../..
```

- [ ] **Step 3: Commit**

```bash
git add modules/budget/main.tf
git commit -m "feat: add FORECASTED budget notification at 100% threshold"
```

---

### Task 9: DynamoDB — deletion protection in prod

**Files:**
- Modify: `modules/dynamodb/main.tf`

- [ ] **Step 1: Add `deletion_protection_enabled` to all 8 tables**

Add `deletion_protection_enabled = var.environment == "prod"` to each `aws_dynamodb_table` resource. Example:

```hcl
resource "aws_dynamodb_table" "users" {
  name                       = "${local.prefix}_users"
  billing_mode               = "PAY_PER_REQUEST"
  hash_key                   = "userId"
  deletion_protection_enabled = var.environment == "prod"
  tags                       = var.tags
  # ... rest unchanged
}
```

Repeat for all 8 tables.

- [ ] **Step 2: Validate**

```bash
cd modules/dynamodb && terraform validate && terraform fmt -check && cd ../..
```

- [ ] **Step 3: Commit**

```bash
git add modules/dynamodb/main.tf
git commit -m "feat: enable deletion protection on DynamoDB tables in prod"
```

---

### Task 10: Cognito — password policy and auth flow hardening

**Files:**
- Modify: `modules/cognito/main.tf`

- [ ] **Step 1: Update password policy to require symbols**

```hcl
password_policy {
  minimum_length    = 8
  require_uppercase = true
  require_lowercase = true
  require_numbers   = true
  require_symbols   = true
}
```

- [ ] **Step 2: Remove `ALLOW_USER_PASSWORD_AUTH` in prod**

Replace `explicit_auth_flows` in `aws_cognito_user_pool_client.app`:

```hcl
explicit_auth_flows = var.environment == "prod" ? [
  "ALLOW_REFRESH_TOKEN_AUTH",
  "ALLOW_USER_SRP_AUTH",
] : [
  "ALLOW_USER_PASSWORD_AUTH",
  "ALLOW_REFRESH_TOKEN_AUTH",
  "ALLOW_USER_SRP_AUTH",
]
```

- [ ] **Step 3: Validate**

```bash
cd modules/cognito && terraform validate && terraform fmt -check && cd ../..
```

- [ ] **Step 4: Commit**

```bash
git add modules/cognito/main.tf
git commit -m "feat: strengthen Cognito password policy and restrict auth flows in prod"
```

---

### Task 11: CloudFront — custom domain support

**Files:**
- Modify: `modules/cloudfront/main.tf`

Note: `variables.tf` was updated with `aliases` and `acm_certificate_arn` in Task 3.

- [ ] **Step 1: Update `viewer_certificate` and `aliases` in `modules/cloudfront/main.tf`**

Replace the `aliases` (currently absent) and `viewer_certificate` block:

```hcl
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = var.price_class
  aliases             = var.aliases

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = local.origin
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  default_cache_behavior {
    target_origin_id       = local.origin
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
    compress    = true
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.acm_certificate_arn == ""
    acm_certificate_arn            = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
    ssl_support_method             = var.acm_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.acm_certificate_arn != "" ? "TLSv1.2_2021" : null
  }

  tags = var.tags
}
```

- [ ] **Step 2: Validate**

```bash
cd modules/cloudfront && terraform validate && terraform fmt -check && cd ../..
```

- [ ] **Step 3: Commit**

```bash
git add modules/cloudfront/main.tf
git commit -m "feat: add optional custom domain and ACM certificate support to CloudFront"
```

---

## Final validation

- [ ] **Run validate across all modules**

```bash
for m in api_gateway budget cloudfront cognito dynamodb ecr ecs ecs_schedule nat_instance; do
  echo "=== $m ===" && cd modules/$m && terraform validate && terraform fmt -check && cd ../..
done
```

Expected: all pass with no errors or formatting issues.
