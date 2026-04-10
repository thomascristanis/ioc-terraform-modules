# ioc-terraform-modules

Reusable Terraform modules for AWS infrastructure.

## Repository rename

This repository was renamed from `liber-infra-modules` to `ioc-terraform-modules`.
If you still reference the old repository name in module sources, update it.

## Modules

| Module | Description |
|---|---|
| `modules/dynamodb` | Generic multi-table DynamoDB module (table map + name prefixing by project/environment) |
| `modules/cognito` | Cognito User Pool + Google OAuth app client |
| `modules/ecr` | ECR repository with lifecycle policy |
| `modules/ecs` | ECS Fargate service (SPOT + on-demand), IAM, CloudWatch, ALB target group |
| `modules/api_gateway` | API Gateway HTTP API with JWT authorizer and VPC link |
| `modules/cloudfront` | S3 + CloudFront distribution with OAC and SPA fallback |
| `modules/vpc` | VPC, public/private subnets, IGW, and route tables |
| `modules/nat_instance` | NAT instance with Elastic IP and private default route |
| `modules/alb` | Public Application Load Balancer with HTTP/HTTPS listener |
| `modules/ecs_cluster` | ECS cluster with optional Container Insights |
| `modules/budget` | AWS Budgets daily cost alert (80% + 100%) |
| `modules/ecs_schedule` | EventBridge Scheduler to stop/start ECS service outside business hours |

## Usage

### Local (development)

```hcl
module "dynamodb" {
  source       = "../../ioc-terraform-modules/modules/dynamodb"
  project_name = "myproject"
  environment  = "dev"
  tables = {
    users = {
      hash_key   = "user_id"
      attributes = [{ name = "user_id", type = "S" }]
    }
  }
}
```

### Git reference (production / CI)

```hcl
module "dynamodb" {
  source       = "git::https://github.com/YOUR_ORG/ioc-terraform-modules.git//modules/dynamodb?ref=v1.0.0"
  project_name = "myproject"
  environment  = "dev"
  tables       = var.dynamodb_tables
}
```

### Direct reference (this org)

```hcl
module "dynamodb" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/dynamodb?ref=master"
  project_name = "myproject"
  environment  = "dev"
  tables       = var.dynamodb_tables
}
```

## Versioning

Tag releases with `vX.Y.Z` for stable references in production.
