# liber-infra-modules

Reusable Terraform modules for AWS infrastructure. Designed for the Liber platform but portable to any project.

## Modules

| Module | Description |
|---|---|
| `modules/dynamodb` | DynamoDB tables (users, books, catalog, tracker, spaces, library_access, subscriptions, rate_limits) |
| `modules/cognito` | Cognito User Pool + Google OAuth app client |
| `modules/ecr` | ECR repository with lifecycle policy |
| `modules/ecs` | ECS Fargate service (SPOT + on-demand), IAM, CloudWatch, ALB target group |
| `modules/api_gateway` | API Gateway HTTP API with JWT authorizer and VPC link |
| `modules/cloudfront` | S3 + CloudFront distribution with OAC and SPA fallback |
| `modules/nat_instance` | t4g.nano NAT instance with iptables masquerade |
| `modules/budget` | AWS Budgets daily cost alert (80% + 100%) |
| `modules/ecs_schedule` | EventBridge Scheduler to stop/start ECS service outside business hours |

## Usage

### Local (development)

```hcl
module "dynamodb" {
  source = "../../liber-infra-modules/modules/dynamodb"
  project_name = "myproject"
  environment  = "dev"
}
```

### Git reference (production / CI)

```hcl
module "dynamodb" {
  source = "git::https://github.com/YOUR_ORG/liber-infra-modules.git//modules/dynamodb?ref=v1.0.0"
  project_name = "myproject"
  environment  = "dev"
}
```

## Versioning

Tag releases with `vX.Y.Z` for stable references in production.