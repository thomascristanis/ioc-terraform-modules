# Design: Liber Infrastructure Split (Network + Cluster)

**Date:** 2026-04-08
**Status:** Approved

## Context

The `liber/infra-base/` project was a monolithic base layer referencing modules (`vpc`, `alb`, `ecs_cluster`) that do not yet exist in `ioc-terraform-modules`. This design splits it into two standalone projects and adds the missing modules.

## Goals

- Create `liber-infra-network`: VPC, subnets, NAT instance
- Create `liber-infra-cluster`: ALB, ECS cluster (reads from network remote state)
- Add missing Terraform modules to `ioc-terraform-modules`: `vpc`, `alb`, `ecs_cluster`
- Update `liber/infra` to read from two remote states (network + cluster)
- Delete `liber/infra-base/` (replaced by the two new projects)

## Architecture

```
ioc-terraform-modules  (new modules: vpc, alb, ecs_cluster)
       ↓
liber-infra-network  (VPC + NAT instance)
       ↓
liber-infra-cluster  (ALB + ECS cluster, reads network remote state)
       ↓
liber/infra          (app layer, reads network + cluster remote states)
```

## Terraform State (S3, no lock)

| Project | State Key |
|---|---|
| liber-infra-network dev | `liber-tf-state/network/dev/terraform.tfstate` |
| liber-infra-network prod | `liber-tf-state/network/prod/terraform.tfstate` |
| liber-infra-cluster dev | `liber-tf-state/cluster/dev/terraform.tfstate` |
| liber-infra-cluster prod | `liber-tf-state/cluster/prod/terraform.tfstate` |
| liber/infra dev | `liber-tf-state/app/dev/terraform.tfstate` (unchanged) |
| liber/infra prod | `liber-tf-state/app/prod/terraform.tfstate` (unchanged) |

No DynamoDB lock table.

## Global Config

- Region: `us-east-1`
- project_name: `liber`
- Environments: `dev`, `prod`
- VPC CIDR: `10.0.0.0/16`
- AZs: `us-east-1a`, `us-east-1b`
- Public subnets: `10.0.1.0/24`, `10.0.2.0/24`
- Private subnets: `10.0.10.0/24`, `10.0.11.0/24`

## Module: `vpc`

**Resources:**
- `aws_vpc` — DNS hostnames + resolution enabled
- `aws_subnet` × 4 — 2 public (map_public_ip_on_launch = true), 2 private
- `aws_internet_gateway`
- `aws_route_table` (public) + default route to IGW + associations
- `aws_route_table` (private) + associations

**Variables:** `project_name`, `environment`, `cidr_block`, `azs`, `public_subnet_cidrs`, `private_subnet_cidrs`, `tags`

**Outputs:** `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `private_route_table_id`

## Module: `alb`

**Resources:**
- `aws_security_group` — ingress 80 + 443 from `0.0.0.0/0`, egress open
- `aws_lb` — internet-facing, type application, public subnets
- `aws_lb_listener` — HTTP:80 in dev (no cert); HTTPS:443 in prod (`certificate_arn` required)

**Variables:** `project_name`, `environment`, `vpc_id`, `public_subnet_ids`, `certificate_arn` (default `""`), `tags`

**Outputs:** `alb_dns_name`, `security_group_id`, `listener_arn`

## Module: `ecs_cluster`

**Resources:**
- `aws_ecs_cluster`
- `aws_ecs_cluster_capacity_providers` — FARGATE + FARGATE_SPOT

**Variables:** `project_name`, `environment`, `tags`

**Outputs:** `cluster_arn`, `cluster_name`

## Project: `liber-infra-network`

**Structure:**
```
envs/
  dev/
    main.tf          # module vpc + module nat_instance
    outputs.tf       # vpc_id, public_subnet_ids, private_subnet_ids, private_route_table_id
    versions.tf
    backend.hcl
    terraform.tfvars
  prod/
    (same structure)
```

**Module sources** (from `ioc-terraform-modules`):
- `vpc` — branch `feat/base-infra-modules`
- `nat_instance` — branch `master`

**Outputs exposed:**
- `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `private_route_table_id`

## Project: `liber-infra-cluster`

**Structure:**
```
envs/
  dev/
    main.tf          # reads network remote state; module alb + module ecs_cluster
    outputs.tf       # cluster_arn, cluster_name, alb_dns_name, alb_security_group_id, alb_listener_arn
    versions.tf
    backend.hcl
    terraform.tfvars
  prod/
    (same structure)
```

**Module sources** (from `ioc-terraform-modules`):
- `alb` — branch `feat/base-infra-modules`
- `ecs_cluster` — branch `feat/base-infra-modules`

**Reads remote state from:** `liber-tf-state/network/{env}/terraform.tfstate`

**Outputs exposed:**
- `cluster_arn`, `cluster_name`, `alb_dns_name`, `alb_security_group_id`, `alb_listener_arn`

## Updates to `liber/infra`

- Replace single `data "terraform_remote_state" "base"` with two:
  - `data "terraform_remote_state" "network"` — reads `liber-tf-state/network/{env}/terraform.tfstate`
  - `data "terraform_remote_state" "cluster"` — reads `liber-tf-state/cluster/{env}/terraform.tfstate`
- Update `locals.base.*` references to use `local.network.*` and `local.cluster.*` appropriately
- Remove variables `base_infra_bucket` and `base_infra_key` from `variables.tf` and `*.tfvars`
- Delete `liber/infra-base/` directory entirely

## Apply Order

```bash
# 1. Network
cd liber-infra-network/envs/dev && terraform init -backend-config=backend.hcl && terraform apply

# 2. Cluster (depends on network state)
cd liber-infra-cluster/envs/dev && terraform init -backend-config=backend.hcl && terraform apply

# 3. App (depends on network + cluster state)
cd liber/infra && terraform init -backend-config=environments/dev.backend.hcl && terraform apply -var-file=environments/dev.tfvars
```

## Git / PRs

Each repo gets its own branch and PR:

| Repo | Branch |
|---|---|
| `ioc-terraform-modules` | `feat/base-infra-modules` |
| `liber-infra-network` | `feat/initial-setup` |
| `liber-infra-cluster` | `feat/initial-setup` |
| `liber` | `feat/split-infra-remote-state` |
