# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A library of reusable Terraform modules for AWS, built for the Liber platform. Each module under `modules/` is standalone and consumed via local path or git ref from a separate infrastructure root (not present here).

## Terraform Workflow

```bash
# Validate a module in isolation
cd modules/<module_name>
terraform init
terraform validate

# Format check
terraform fmt -check -recursive

# Auto-format
terraform fmt -recursive
```

There is no root-level `main.tf` — modules are consumed by external projects. There are no tests in this repo.

## Module Conventions

- All modules share the same two required variables: `project_name` and `environment`.
- Resource naming pattern: `${var.project_name}-${var.environment}-<suffix>` (hyphens) for AWS resource names; `${var.project_name}_${var.environment}_<suffix>` (underscores) for DynamoDB table names.
- `environment` is `dev` or `prd` (production is always `prd`, never `prod`). Every module enforces this with a `validation` block on the variable, so an invalid value fails during `plan`. Some behavior branches on it (e.g., CloudWatch log retention, SPOT-only vs SPOT+on-demand in ECS).

## Architecture Overview

The modules form a layered AWS stack:

**Data layer** (`dynamodb`, `rds`): `dynamodb` provisions 8 PAY_PER_REQUEST tables with abbreviated attribute names in hot paths (e.g., `apid`, `sp`, `s`, `cp`, `tp`, `pg`); `library_access` and `rate_limits` use DynamoDB TTL. `rds` provisions a PostgreSQL instance in private subnets (encrypted gp3 storage with autoscaling; Multi-AZ off by default even in `prd`), reachable only from the security groups passed via `allowed_security_group_ids` (typically the ECS app SG). Master credentials are generated with `random_password` and stored in Secrets Manager — only the secret ARN is exported as an output, never the password. Per-environment defaults (instance class, deletion protection, backup retention, final-snapshot behavior) are overridable.

**Auth** (`cognito`): Cognito User Pool with Google OAuth client. The `api_gateway` module consumes Cognito's issuer URL and client ID for JWT authorization.

**Compute** (`ecs`): ECS Fargate with SPOT capacity provider. `use_spot_only = true` for dev (pure SPOT), `false` for prod (SPOT + on-demand fallback). The task role gets DynamoDB access scoped to `${project_name}_${environment}_*` tables. The ECS module also creates the ALB target group and listener rule — it expects an externally-created ALB and cluster.

**API** (`api_gateway`): HTTP API Gateway with a Cognito JWT authorizer. Routes `/auth/**`, `/webhooks/**`, and `GET /health` are public; everything else requires a valid JWT. Traffic is routed to the ALB via VPC link.

**Frontend** (`cloudfront`): Private S3 bucket + CloudFront with OAC (sigv4). Uses `PriceClass_100` (US/Canada/Europe). Returns `index.html` on 403/404 for SPA routing.

**Networking** (`nat_instance`): Cost-optimized NAT using a `t4g.nano` AL2023 ARM instance with iptables masquerade instead of a NAT Gateway. Writes a route directly to the private route table.

**Ops** (`budget`, `ecs_schedule`): `budget` sets 80%/100% cost alerts. `ecs_schedule` uses EventBridge Scheduler to stop the ECS service at 22:00 UTC and start it at 08:00 UTC (dev cost savings).

## Key Wiring Between Modules

- `ecs` outputs `security_group_id` → consumed by `api_gateway` as `ecs_security_group_id` for the VPC link.
- `ecs` outputs `security_group_id` → consumed by `rds` as `allowed_security_group_ids` to scope database ingress to the app.
- `rds` outputs `credentials_secret_arn` → grant the ECS task role read access so the app can pull DB credentials from Secrets Manager.
- `ecs` outputs `alb_target_group_arn` → consumed by the ALB listener (external).
- `cognito` outputs `client_id` and `issuer_url` → consumed by `api_gateway`.
- `ecs_schedule` takes `cluster_name` and `service_name` from `ecs` outputs.