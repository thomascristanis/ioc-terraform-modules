# Infrastructure Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split `liber/infra-base` into two standalone projects (`liber-infra-network` and `liber-infra-cluster`), wire `liber/infra` to read from both, and open PRs in all four repos.

**Architecture:** `liber-infra-network` creates VPC + NAT and exposes outputs via S3 remote state. `liber-infra-cluster` reads network state and creates ALB + ECS cluster. `liber/infra` reads both remote states to wire the app layer. Each project has `envs/dev/` and `envs/prod/` directories with hardcoded locals — no variables file needed.

**Tech Stack:** Terraform >= 1.7, AWS provider ~> 5.0, S3 backend (no lock), GitHub CLI (`gh`)

---

## Context

- `liber-infra-modules` `feat/base-infra-modules` branch already contains `modules/vpc`, `modules/alb`, `modules/ecs_cluster` — no new module code needed, just a PR.
- `liber-infra-network/` and `liber-infra-cluster/` folders exist locally but are empty.
- `liber/infra-base/` is the old monolithic base — will be deleted.
- `liber/infra/main.tf` currently reads a single `terraform_remote_state "base"` — will be split into `"network"` and `"cluster"`.

## State Paths

| Project | Key |
|---|---|
| network dev | `network/dev/terraform.tfstate` |
| network prod | `network/prod/terraform.tfstate` |
| cluster dev | `cluster/dev/terraform.tfstate` |
| cluster prod | `cluster/prod/terraform.tfstate` |
| app dev/prod | `app/dev/terraform.tfstate` (unchanged) |

Bucket: `liber-tf-state`. No DynamoDB lock.

## Apply Order (after all PRs merged)

```bash
# 1 — Network
cd liber-infra-network/envs/dev
terraform init -backend-config=backend.hcl && terraform apply

# 2 — Cluster (depends on network state)
cd liber-infra-cluster/envs/dev
terraform init -backend-config=backend.hcl && terraform apply

# 3 — App (depends on network + cluster state)
cd liber/infra
terraform init -backend-config=environments/dev.backend.hcl
terraform apply -var-file=environments/dev.tfvars
```

---

## Task 1: PR for liber-infra-modules feat/base-infra-modules

The three modules (vpc, alb, ecs_cluster) already exist on this branch. Just validate and open the PR.

**Files:** no changes — modules already committed on `feat/base-infra-modules`

- [ ] **Step 1: Validate modules**

```bash
cd /Users/thomascristanis/source/liber-infra-modules

# Check formatting
terraform fmt -check -recursive modules/vpc modules/alb modules/ecs_cluster

# Validate each module (requires a stub providers.tf — skip if no AWS creds available locally;
# fmt check is sufficient for CI)
```

Expected: no formatting errors reported.

- [ ] **Step 2: Push branch and open PR**

```bash
cd /Users/thomascristanis/source/liber-infra-modules
git push origin feat/base-infra-modules

gh pr create \
  --base master \
  --head feat/base-infra-modules \
  --title "feat: add vpc, alb, and ecs_cluster modules" \
  --body "$(cat <<'EOF'
## Summary
- Add `modules/vpc`: VPC, subnets (public/private), IGW, route tables
- Add `modules/alb`: internet-facing ALB, security group, HTTP/HTTPS listener
- Add `modules/ecs_cluster`: ECS cluster with FARGATE + FARGATE_SPOT capacity providers

## Usage
Referenced by `liber-infra-network` and `liber-infra-cluster` via `?ref=feat/base-infra-modules`.
After merge, downstream projects should update the ref to `master`.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Expected: PR URL printed.

- [ ] **Step 3: Commit**

No code changes in this task — PR is the deliverable.

---

## Task 2: Initialize liber-infra-network git repo

**Files:**
- Create: `/Users/thomascristanis/source/liber-infra-network/.gitignore`

- [ ] **Step 1: Init git and create .gitignore**

```bash
cd /Users/thomascristanis/source/liber-infra-network
git init
```

Create `.gitignore`:
```
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars.backup
.terraform.lock.hcl
```

- [ ] **Step 2: Create initial commit on main and push**

```bash
cd /Users/thomascristanis/source/liber-infra-network
git add .gitignore
git commit -m "chore: initial commit"
```

- [ ] **Step 3: Create GitHub repo and push main**

```bash
gh repo create thomascristanis/liber-infra-network \
  --private \
  --description "Liber network layer: VPC, subnets, NAT instance"
git remote add origin git@github.com:thomascristanis/liber-infra-network.git
git push -u origin main
```

- [ ] **Step 4: Create feature branch**

```bash
git checkout -b feat/initial-setup
```

---

## Task 3: Create liber-infra-network envs/dev

**Files:**
- Create: `envs/dev/versions.tf`
- Create: `envs/dev/providers.tf`
- Create: `envs/dev/backend.hcl`
- Create: `envs/dev/main.tf`
- Create: `envs/dev/outputs.tf`

All paths relative to `/Users/thomascristanis/source/liber-infra-network/`.

- [ ] **Step 1: Create envs/dev/versions.tf**

```hcl
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}
```

- [ ] **Step 2: Create envs/dev/providers.tf**

```hcl
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "liber"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}
```

- [ ] **Step 3: Create envs/dev/backend.hcl**

```hcl
bucket  = "liber-tf-state"
key     = "network/dev/terraform.tfstate"
region  = "us-east-1"
encrypt = true
```

- [ ] **Step 4: Create envs/dev/main.tf**

```hcl
locals {
  project_name = "liber"
  environment  = "dev"

  common_tags = {
    Environment = "dev"
  }
}

module "vpc" {
  source = "git::https://github.com/thomascristanis/liber-infra-modules.git//modules/vpc?ref=feat/base-infra-modules"

  project_name         = local.project_name
  environment          = local.environment
  cidr_block           = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  tags                 = local.common_tags
}

module "nat_instance" {
  source = "git::https://github.com/thomascristanis/liber-infra-modules.git//modules/nat_instance?ref=master"

  project_name           = local.project_name
  environment            = local.environment
  vpc_id                 = module.vpc.vpc_id
  public_subnet_id       = module.vpc.public_subnet_ids[0]
  private_route_table_id = module.vpc.private_route_table_id
  tags                   = local.common_tags
}
```

- [ ] **Step 5: Create envs/dev/outputs.tf**

```hcl
output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.vpc.private_subnet_ids
}

output "private_route_table_id" {
  description = "ID of the private route table."
  value       = module.vpc.private_route_table_id
}
```

- [ ] **Step 6: Verify formatting**

```bash
cd /Users/thomascristanis/source/liber-infra-network
terraform fmt -check -recursive envs/dev/
```

Expected: no output (no formatting issues).

- [ ] **Step 7: Commit**

```bash
cd /Users/thomascristanis/source/liber-infra-network
git add envs/dev/ .gitignore
git commit -m "feat: add network layer envs/dev (VPC + NAT instance)"
```

---

## Task 4: Create liber-infra-network envs/prod

**Files:**
- Create: `envs/prod/versions.tf`
- Create: `envs/prod/providers.tf`
- Create: `envs/prod/backend.hcl`
- Create: `envs/prod/main.tf`
- Create: `envs/prod/outputs.tf`

- [ ] **Step 1: Create envs/prod/versions.tf**

Identical to dev:
```hcl
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}
```

- [ ] **Step 2: Create envs/prod/providers.tf**

```hcl
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "liber"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}
```

- [ ] **Step 3: Create envs/prod/backend.hcl**

```hcl
bucket  = "liber-tf-state"
key     = "network/prod/terraform.tfstate"
region  = "us-east-1"
encrypt = true
```

- [ ] **Step 4: Create envs/prod/main.tf**

```hcl
locals {
  project_name = "liber"
  environment  = "prod"

  common_tags = {
    Environment = "prod"
  }
}

module "vpc" {
  source = "git::https://github.com/thomascristanis/liber-infra-modules.git//modules/vpc?ref=feat/base-infra-modules"

  project_name         = local.project_name
  environment          = local.environment
  cidr_block           = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  tags                 = local.common_tags
}

module "nat_instance" {
  source = "git::https://github.com/thomascristanis/liber-infra-modules.git//modules/nat_instance?ref=master"

  project_name           = local.project_name
  environment            = local.environment
  vpc_id                 = module.vpc.vpc_id
  public_subnet_id       = module.vpc.public_subnet_ids[0]
  private_route_table_id = module.vpc.private_route_table_id
  tags                   = local.common_tags
}
```

- [ ] **Step 5: Create envs/prod/outputs.tf**

```hcl
output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.vpc.private_subnet_ids
}

output "private_route_table_id" {
  description = "ID of the private route table."
  value       = module.vpc.private_route_table_id
}
```

- [ ] **Step 6: Verify formatting**

```bash
cd /Users/thomascristanis/source/liber-infra-network
terraform fmt -check -recursive envs/prod/
```

Expected: no output.

- [ ] **Step 7: Commit**

```bash
git add envs/prod/
git commit -m "feat: add network layer envs/prod (VPC + NAT instance)"
```

---

## Task 5: Push liber-infra-network and open PR

- [ ] **Step 1: Push branch**

```bash
cd /Users/thomascristanis/source/liber-infra-network
git push -u origin feat/initial-setup
```

- [ ] **Step 2: Open PR**

```bash
gh pr create \
  --base main \
  --head feat/initial-setup \
  --title "feat: initial network layer (VPC + NAT)" \
  --body "$(cat <<'EOF'
## Summary
- Creates VPC `10.0.0.0/16` with 2 public and 2 private subnets across `us-east-1a/b`
- Deploys NAT instance (`t4g.nano` ARM) in the public subnet for private subnet egress
- Exposes `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `private_route_table_id` via S3 remote state

## State
- dev: `s3://liber-tf-state/network/dev/terraform.tfstate`
- prod: `s3://liber-tf-state/network/prod/terraform.tfstate`

## Apply
```bash
cd envs/dev
terraform init -backend-config=backend.hcl
terraform apply
```

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Expected: PR URL printed.

---

## Task 6: Initialize liber-infra-cluster git repo

**Files:**
- Create: `/Users/thomascristanis/source/liber-infra-cluster/.gitignore`

- [ ] **Step 1: Init git and create .gitignore**

```bash
cd /Users/thomascristanis/source/liber-infra-cluster
git init
```

Create `.gitignore`:
```
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars.backup
.terraform.lock.hcl
```

- [ ] **Step 2: Create initial commit on main and push**

```bash
cd /Users/thomascristanis/source/liber-infra-cluster
git add .gitignore
git commit -m "chore: initial commit"
```

- [ ] **Step 3: Create GitHub repo and push main**

```bash
gh repo create thomascristanis/liber-infra-cluster \
  --private \
  --description "Liber cluster layer: ALB + ECS cluster"
git remote add origin git@github.com:thomascristanis/liber-infra-cluster.git
git push -u origin main
```

- [ ] **Step 4: Create feature branch**

```bash
git checkout -b feat/initial-setup
```

---

## Task 7: Create liber-infra-cluster envs/dev

**Files:**
- Create: `envs/dev/versions.tf`
- Create: `envs/dev/providers.tf`
- Create: `envs/dev/backend.hcl`
- Create: `envs/dev/main.tf`
- Create: `envs/dev/outputs.tf`

All paths relative to `/Users/thomascristanis/source/liber-infra-cluster/`.

- [ ] **Step 1: Create envs/dev/versions.tf**

```hcl
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}
```

- [ ] **Step 2: Create envs/dev/providers.tf**

```hcl
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "liber"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}
```

- [ ] **Step 3: Create envs/dev/backend.hcl**

```hcl
bucket  = "liber-tf-state"
key     = "cluster/dev/terraform.tfstate"
region  = "us-east-1"
encrypt = true
```

- [ ] **Step 4: Create envs/dev/main.tf**

```hcl
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "liber-tf-state"
    key    = "network/dev/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  project_name = "liber"
  environment  = "dev"
  network      = data.terraform_remote_state.network.outputs

  common_tags = {
    Environment = "dev"
  }
}

module "alb" {
  source = "git::https://github.com/thomascristanis/liber-infra-modules.git//modules/alb?ref=feat/base-infra-modules"

  project_name      = local.project_name
  environment       = local.environment
  vpc_id            = local.network.vpc_id
  public_subnet_ids = local.network.public_subnet_ids
  # certificate_arn not set — dev uses HTTP:80 listener
  tags = local.common_tags
}

module "ecs_cluster" {
  source = "git::https://github.com/thomascristanis/liber-infra-modules.git//modules/ecs_cluster?ref=feat/base-infra-modules"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags
}
```

- [ ] **Step 5: Create envs/dev/outputs.tf**

```hcl
output "cluster_arn" {
  description = "ARN of the ECS cluster."
  value       = module.ecs_cluster.cluster_arn
}

output "cluster_name" {
  description = "Name of the ECS cluster."
  value       = module.ecs_cluster.cluster_name
}

output "alb_dns_name" {
  description = "DNS name of the ALB."
  value       = module.alb.alb_dns_name
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB."
  value       = module.alb.security_group_id
}

output "alb_listener_arn" {
  description = "ARN of the active ALB listener (HTTP in dev, HTTPS in prod)."
  value       = module.alb.listener_arn
}
```

- [ ] **Step 6: Verify formatting**

```bash
cd /Users/thomascristanis/source/liber-infra-cluster
terraform fmt -check -recursive envs/dev/
```

Expected: no output.

- [ ] **Step 7: Commit**

```bash
cd /Users/thomascristanis/source/liber-infra-cluster
git add envs/dev/ .gitignore
git commit -m "feat: add cluster layer envs/dev (ALB + ECS cluster)"
```

---

## Task 8: Create liber-infra-cluster envs/prod

**Files:**
- Create: `envs/prod/versions.tf`
- Create: `envs/prod/providers.tf`
- Create: `envs/prod/backend.hcl`
- Create: `envs/prod/main.tf`
- Create: `envs/prod/outputs.tf`

- [ ] **Step 1: Create envs/prod/versions.tf**

```hcl
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}
```

- [ ] **Step 2: Create envs/prod/providers.tf**

```hcl
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "liber"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}
```

- [ ] **Step 3: Create envs/prod/backend.hcl**

```hcl
bucket  = "liber-tf-state"
key     = "cluster/prod/terraform.tfstate"
region  = "us-east-1"
encrypt = true
```

- [ ] **Step 4: Create envs/prod/main.tf**

```hcl
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "liber-tf-state"
    key    = "network/prod/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  project_name = "liber"
  environment  = "prod"
  network      = data.terraform_remote_state.network.outputs

  common_tags = {
    Environment = "prod"
  }
}

module "alb" {
  source = "git::https://github.com/thomascristanis/liber-infra-modules.git//modules/alb?ref=feat/base-infra-modules"

  project_name      = local.project_name
  environment       = local.environment
  vpc_id            = local.network.vpc_id
  public_subnet_ids = local.network.public_subnet_ids
  # certificate_arn = ""  # Set when ACM certificate is available for prod domain
  tags = local.common_tags
}

module "ecs_cluster" {
  source = "git::https://github.com/thomascristanis/liber-infra-modules.git//modules/ecs_cluster?ref=feat/base-infra-modules"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags
}
```

- [ ] **Step 5: Create envs/prod/outputs.tf**

```hcl
output "cluster_arn" {
  description = "ARN of the ECS cluster."
  value       = module.ecs_cluster.cluster_arn
}

output "cluster_name" {
  description = "Name of the ECS cluster."
  value       = module.ecs_cluster.cluster_name
}

output "alb_dns_name" {
  description = "DNS name of the ALB."
  value       = module.alb.alb_dns_name
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB."
  value       = module.alb.security_group_id
}

output "alb_listener_arn" {
  description = "ARN of the active ALB listener (HTTP in dev, HTTPS in prod)."
  value       = module.alb.listener_arn
}
```

- [ ] **Step 6: Verify formatting**

```bash
cd /Users/thomascristanis/source/liber-infra-cluster
terraform fmt -check -recursive envs/prod/
```

Expected: no output.

- [ ] **Step 7: Commit**

```bash
git add envs/prod/
git commit -m "feat: add cluster layer envs/prod (ALB + ECS cluster)"
```

---

## Task 9: Push liber-infra-cluster and open PR

- [ ] **Step 1: Push branch**

```bash
cd /Users/thomascristanis/source/liber-infra-cluster
git push -u origin feat/initial-setup
```

- [ ] **Step 2: Open PR**

```bash
gh pr create \
  --base main \
  --head feat/initial-setup \
  --title "feat: initial cluster layer (ALB + ECS cluster)" \
  --body "$(cat <<'EOF'
## Summary
- Creates internet-facing ALB with HTTP:80 listener in dev (no cert required)
- Creates ECS cluster `liber-dev` with FARGATE + FARGATE_SPOT capacity providers
- Reads VPC/subnet IDs from `liber-infra-network` remote state
- Exposes `cluster_arn`, `cluster_name`, `alb_dns_name`, `alb_security_group_id`, `alb_listener_arn` via S3 remote state

## State
- dev: `s3://liber-tf-state/cluster/dev/terraform.tfstate`
- prod: `s3://liber-tf-state/cluster/prod/terraform.tfstate`

## Apply order
Apply `liber-infra-network` first, then:
```bash
cd envs/dev
terraform init -backend-config=backend.hcl
terraform apply
```

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Expected: PR URL printed.

---

## Task 10: Update liber/infra to read from two remote states

**Files:**
- Modify: `/Users/thomascristanis/source/liber/infra/main.tf`
- Modify: `/Users/thomascristanis/source/liber/infra/variables.tf`
- Modify: `/Users/thomascristanis/source/liber/infra/environments/dev.tfvars`
- Modify: `/Users/thomascristanis/source/liber/infra/environments/prod.tfvars`

- [ ] **Step 1: Create branch in liber repo**

```bash
cd /Users/thomascristanis/source/liber
git checkout -b feat/split-infra-remote-state
```

- [ ] **Step 2: Replace main.tf**

Full new content of `/Users/thomascristanis/source/liber/infra/main.tf`:

```hcl
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "liber-tf-state"
    key    = "network/${var.environment}/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "cluster" {
  backend = "s3"
  config = {
    bucket = "liber-tf-state"
    key    = "cluster/${var.environment}/terraform.tfstate"
    region = var.aws_region
  }
}

locals {
  network = data.terraform_remote_state.network.outputs
  cluster = data.terraform_remote_state.cluster.outputs

  common_tags = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
  }
}

module "dynamodb" {
  source       = "git::https://github.com/thomascristanis/liber-infra-modules.git//modules/dynamodb?ref=master"
  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

module "cognito" {
  source               = "git::https://github.com/thomascristanis/liber-infra-modules.git//modules/cognito?ref=master"
  project_name         = var.project_name
  environment          = var.environment
  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret
  callback_urls        = ["https://${module.cloudfront.distribution_domain}/auth/callback"]
  logout_urls          = ["https://${module.cloudfront.distribution_domain}"]
  tags                 = local.common_tags
}

module "ecr" {
  source              = "git::https://github.com/thomascristanis/liber-infra-modules.git//modules/ecr?ref=master"
  project_name        = var.project_name
  environment         = var.environment
  image_count_to_keep = var.environment == "dev" ? 3 : 5
  tags                = local.common_tags
}

module "cloudfront" {
  source       = "git::https://github.com/thomascristanis/liber-infra-modules.git//modules/cloudfront?ref=master"
  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

module "ecs" {
  source                = "git::https://github.com/thomascristanis/liber-infra-modules.git//modules/ecs?ref=master"
  project_name          = var.project_name
  environment           = var.environment
  cluster_arn           = local.cluster.cluster_arn
  cluster_name          = local.cluster.cluster_name
  private_subnet_ids    = local.network.private_subnet_ids
  alb_listener_arn      = local.cluster.alb_listener_arn
  alb_security_group_id = local.cluster.alb_security_group_id
  vpc_id                = local.network.vpc_id
  container_image       = var.container_image
  app_port              = var.app_port
  aws_region            = var.aws_region
  use_spot_only         = var.environment == "dev"
  tags                  = local.common_tags
  environment_variables = {
    NODE_ENV                      = var.environment
    PORT                          = tostring(var.app_port)
    AWS_REGION                    = var.aws_region
    DYNAMODB_TABLE_USERS          = module.dynamodb.users_table_name
    DYNAMODB_TABLE_BOOKS          = module.dynamodb.books_table_name
    DYNAMODB_TABLE_CATALOG        = module.dynamodb.catalog_table_name
    DYNAMODB_TABLE_TRACKER        = module.dynamodb.tracker_table_name
    DYNAMODB_TABLE_SPACES         = module.dynamodb.spaces_table_name
    DYNAMODB_TABLE_LIBRARY_ACCESS = module.dynamodb.library_access_table_name
    DYNAMODB_TABLE_RATE_LIMITS    = module.dynamodb.rate_limits_table_name
    DYNAMODB_TABLE_SUBSCRIPTIONS  = module.dynamodb.subscriptions_table_name
    COGNITO_USER_POOL_ID          = module.cognito.user_pool_id
    COGNITO_CLIENT_ID             = module.cognito.client_id
    COGNITO_ISSUER                = module.cognito.issuer_url
  }
}

module "api_gateway" {
  source                = "git::https://github.com/thomascristanis/liber-infra-modules.git//modules/api_gateway?ref=master"
  project_name          = var.project_name
  environment           = var.environment
  cognito_issuer        = module.cognito.issuer_url
  cognito_client_id     = module.cognito.client_id
  alb_dns_name          = local.cluster.alb_dns_name
  vpc_id                = local.network.vpc_id
  private_subnet_ids    = local.network.private_subnet_ids
  ecs_security_group_id = module.ecs.security_group_id
  cors_allowed_origins  = var.environment == "dev" ? ["http://localhost:5173", "http://localhost:3000"] : ["https://${module.cloudfront.distribution_domain}"]
  tags                  = local.common_tags
}

module "budget" {
  source          = "git::https://github.com/thomascristanis/liber-infra-modules.git//modules/budget?ref=master"
  project_name    = var.project_name
  environment     = var.environment
  daily_limit_usd = var.daily_budget_limit_usd
  alert_email     = var.budget_alert_email
}

# ECS schedule only in dev
module "ecs_schedule" {
  count  = var.environment == "dev" ? 1 : 0
  source = "git::https://github.com/thomascristanis/liber-infra-modules.git//modules/ecs_schedule?ref=master"

  project_name = var.project_name
  environment  = var.environment
  cluster_name = local.cluster.cluster_name
  service_name = module.ecs.service_name
  aws_region   = var.aws_region
  tags         = local.common_tags
}
```

- [ ] **Step 3: Update variables.tf — remove base_infra_bucket and base_infra_key**

Remove these two variable blocks from `/Users/thomascristanis/source/liber/infra/variables.tf`:

```hcl
variable "base_infra_bucket" {
  description = "S3 bucket name for base infra Terraform remote state"
  type        = string
}

variable "base_infra_key" {
  description = "S3 key for base infra Terraform remote state"
  type        = string
}
```

The file after removal should have: `environment`, `aws_region`, `project_name`, `daily_budget_limit_usd`, `budget_alert_email`, `google_client_id`, `google_client_secret`, `container_image`, `app_port`.

- [ ] **Step 4: Update environments/dev.tfvars — remove base_infra_* lines**

Full new content of `/Users/thomascristanis/source/liber/infra/environments/dev.tfvars`:

```hcl
environment  = "dev"
aws_region   = "us-east-1"
project_name = "liber"

# Budget
daily_budget_limit_usd = 5
budget_alert_email     = "thomascristanis@gmail.com"

# Google OAuth (preencher antes do apply)
# google_client_id     = ""
# google_client_secret = ""

# Container image — nginx como placeholder até o primeiro build CI/CD
container_image = "nginx:latest"
app_port        = 3000
```

- [ ] **Step 5: Update environments/prod.tfvars — remove base_infra_* lines**

Full new content of `/Users/thomascristanis/source/liber/infra/environments/prod.tfvars`:

```hcl
environment            = "prod"
aws_region             = "us-east-1"
project_name           = "liber"
daily_budget_limit_usd = 4.00
budget_alert_email     = "thomascristanis@gmail.com"
# google_client_id     = "..."  # Set via -var flag or CI/CD secret
# google_client_secret = "..."  # Set via -var flag or CI/CD secret
```

- [ ] **Step 6: Verify formatting**

```bash
cd /Users/thomascristanis/source/liber/infra
terraform fmt -check
```

Expected: no output.

- [ ] **Step 7: Commit**

```bash
cd /Users/thomascristanis/source/liber
git add infra/main.tf infra/variables.tf infra/environments/dev.tfvars infra/environments/prod.tfvars
git commit -m "refactor(infra): split base remote state into network + cluster"
```

---

## Task 11: Delete liber/infra-base

- [ ] **Step 1: Delete infra-base directory**

```bash
cd /Users/thomascristanis/source/liber
rm -rf infra-base/
```

- [ ] **Step 2: Commit**

```bash
git add -A infra-base/
git commit -m "chore: remove infra-base (replaced by liber-infra-network + liber-infra-cluster)"
```

---

## Task 12: Push liber branch and open PR

- [ ] **Step 1: Push branch**

```bash
cd /Users/thomascristanis/source/liber
git push -u origin feat/split-infra-remote-state
```

- [ ] **Step 2: Open PR**

```bash
gh pr create \
  --base master \
  --head feat/split-infra-remote-state \
  --title "refactor(infra): split base infra into network + cluster remote states" \
  --body "$(cat <<'EOF'
## Summary
- Replace single `terraform_remote_state "base"` with two separate reads:
  - `terraform_remote_state "network"` → `s3://liber-tf-state/network/{env}/terraform.tfstate`
  - `terraform_remote_state "cluster"` → `s3://liber-tf-state/cluster/{env}/terraform.tfstate`
- Remove `base_infra_bucket` and `base_infra_key` variables (no longer needed — paths are fixed)
- Delete `infra-base/` directory (replaced by `liber-infra-network` and `liber-infra-cluster` repos)

## Related repos
- `liber-infra-network` — provides VPC/subnet outputs
- `liber-infra-cluster` — provides ALB/ECS cluster outputs

## Apply order
1. `liber-infra-network envs/dev`
2. `liber-infra-cluster envs/dev`
3. `liber/infra` with `dev.tfvars`

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Expected: PR URL printed.
