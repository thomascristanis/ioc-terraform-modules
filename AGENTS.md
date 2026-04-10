# Repository Guidelines

## Project Structure & Module Organization
This repository contains reusable Terraform modules under `modules/`.
Each module lives in `modules/<module_name>/` with a consistent file layout:
- `main.tf`: resources and core logic
- `variables.tf`: input contract
- `outputs.tf`: exported values
- `versions.tf`: Terraform/provider constraints

`docs/` holds design/planning notes. Do not add environment-specific root stacks here; those belong in consumer repos.

## Build, Test, and Development Commands
Run checks from repo root unless noted:
- `terraform fmt -check -recursive` - formatting gate for CI/PR.
- `terraform fmt -recursive` - auto-format all modules.
- `cd modules/<module_name> && terraform init` - initialize one module in isolation.
- `cd modules/<module_name> && terraform validate` - validate syntax and schema.

Example:
`cd modules/ecs && terraform init && terraform validate`

## Coding Style & Naming Conventions
- Keep Terraform output canonical via `terraform fmt` (2-space indentation).
- Shared required inputs are `project_name` and `environment`.
- Resource naming convention:
  - AWS names: `${var.project_name}-${var.environment}-<suffix>`
  - DynamoDB names: `${var.project_name}_${var.environment}_<suffix>`
- Keep modules composable: no hardcoded account IDs, regions, or environment-only behavior without explicit variables.

## Testing Guidelines
There is no dedicated automated test harness in this repo. For every changed module, run:
- `terraform fmt -check -recursive`
- `terraform validate` inside the changed module directory

When behavior changes materially, include a sample consumer snippet in the PR description.

## Commit & Pull Request Guidelines
Use Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`) with concise scope, e.g. `feat: add optional custom domain support to cloudfront`.

PRs should include changed modules, backward-compatibility notes, required variable/output changes, and migration guidance when inputs/outputs are modified.
