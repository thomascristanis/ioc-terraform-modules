# Terraform Best Practices Review — Design

**Date:** 2026-04-08  
**Scope:** All 9 modules in `ioc-terraform-modules`  
**Strategy:** Risk-tiered — changes grouped by operational impact

---

## Camada 1 — Sem risco (zero downtime, non-destructive)

### `versions.tf` em todos os módulos

Adicionar `versions.tf` em cada um dos 9 módulos:

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

Módulos afetados: `api_gateway`, `budget`, `cloudfront`, `cognito`, `dynamodb`, `ecr`, `ecs`, `ecs_schedule`, `nat_instance`.

### Descrições de variáveis

Adicionar `description` às variáveis inline sem descrição e padronizar a ordem `description` → `type` → `default`:
- `ecr/variables.tf` — `project_name`, `environment`
- `ecs/variables.tf` — 11 variáveis inline sem descrição
- `nat_instance/variables.tf` — todas as 5 variáveis
- `cloudfront/variables.tf` — `project_name`, `environment`
- `dynamodb/variables.tf` — padronizar ordem (`type` antes de `description` atualmente)

Já corretos (não modificar): `budget`, `ecs_schedule`, `cognito`, `api_gateway`.

### Variável `tags`

Adicionar em todos os módulos:

```hcl
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

Aplicar via `tags = var.tags` (ou `merge(var.tags, { Name = "..." })`) em todos os recursos que suportam tags.

### Valores hardcoded → variáveis

| Módulo | Valor atual | Nova variável | Default |
|---|---|---|---|
| `ecs_schedule` | `cron(0 22 * * ? *)` | `stop_cron` | `"cron(0 22 * * ? *)"` |
| `ecs_schedule` | `cron(0 8 * * ? *)` | `start_cron` | `"cron(0 8 * * ? *)"` |
| `ecs_schedule` | `DesiredCount = 0` | `scale_down_count` | `0` |
| `ecs_schedule` | `DesiredCount = 1` | `scale_up_count` | `1` |
| `cloudfront` | `"PriceClass_100"` | `price_class` | `"PriceClass_100"` |
| `ecs` | `"/health"` | `health_check_path` | `"/health"` |
| `ecs` | `100` (listener priority) | `alb_listener_priority` | `100` |
| `ecs` | `dev ? 7 : 14` (log retention) | `log_retention_days` | `7` |

---

## Camada 2 — Destrutivo controlado (destroy/recreate no state, sem perda de dados)

### DynamoDB — todas as 8 tabelas

```hcl
point_in_time_recovery {
  enabled = true
}

server_side_encryption {
  enabled = true  # AES-256 gerenciado pela AWS (já é o default, agora explícito)
}
```

### ECR

```hcl
image_tag_mutability = var.environment == "prod" ? "IMMUTABLE" : "MUTABLE"

encryption_configuration {
  encryption_type = "AES256"
}
```

Impede sobrescrita de tags de imagem em produção.

### NAT instance — Elastic IP

Adicionar `aws_eip` e `aws_eip_association` para fixar o IP público:

```hcl
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = var.tags
}

resource "aws_eip_association" "nat" {
  instance_id   = aws_instance.nat.id
  allocation_id = aws_eip.nat.id
}
```

Atualizar `aws_route` para usar `network_interface_id` da instância (sem mudança funcional, mais explícito).

---

## Camada 3 — Novas features

### Budget — notificação FORECASTED

Adicionar terceiro bloco `notification` com `notification_type = "FORECASTED"` em 100% — alerta preditivo antes de estourar.

### DynamoDB — proteção contra delete em produção

```hcl
deletion_protection_enabled = var.environment == "prod"
```

### Cognito — hardening

1. `require_symbols = true` na `password_policy` (alinhado com NIST SP 800-63B)
2. `ALLOW_USER_PASSWORD_AUTH` removido dos `explicit_auth_flows` quando `environment == "prod"` — força SRP, mantém em `dev` para facilitar testes via CLI/SDK

### ECS — grace period no serviço

```hcl
variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore failing health checks on new tasks (boot time)"
  type        = number
  default     = 60
}
```

Aplicar em `aws_ecs_service.app`.

### CloudFront — suporte a domínio customizado

```hcl
variable "aliases" {
  description = "Custom domain aliases for the CloudFront distribution"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for custom domain (us-east-1). Required when aliases is non-empty."
  type        = string
  default     = ""
}
```

Lógica no `viewer_certificate`:
```hcl
viewer_certificate {
  cloudfront_default_certificate = var.acm_certificate_arn == ""
  acm_certificate_arn            = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
  ssl_support_method             = var.acm_certificate_arn != "" ? "sni-only" : null
  minimum_protocol_version       = var.acm_certificate_arn != "" ? "TLSv1.2_2021" : null
}
```

---

## Resumo de arquivos afetados

| Módulo | Arquivos modificados | Novos arquivos |
|---|---|---|
| Todos (9) | `variables.tf` | `versions.tf` |
| `api_gateway` | `variables.tf` | `versions.tf` |
| `budget` | `main.tf`, `variables.tf` | `versions.tf` |
| `cloudfront` | `main.tf`, `variables.tf` | `versions.tf` |
| `cognito` | `main.tf` | `versions.tf` |
| `dynamodb` | `main.tf` | `versions.tf` |
| `ecr` | `main.tf`, `variables.tf` | `versions.tf` |
| `ecs` | `main.tf`, `variables.tf` | `versions.tf` |
| `ecs_schedule` | `main.tf`, `variables.tf` | `versions.tf` |
| `nat_instance` | `main.tf`, `variables.tf` | `versions.tf` |
