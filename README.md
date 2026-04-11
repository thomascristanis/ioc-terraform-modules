# IoC Terraform Modules

Pare de montar infraestrutura AWS do zero a cada projeto.  
`ioc-terraform-modules` entrega blocos Terraform prontos para uso, com padrões consistentes, menor risco operacional e mais velocidade de entrega.

## Índice

- [Por Que Este Projeto Existe](#por-que-este-projeto-existe)
- [Problemas Que Resolve](#problemas-que-resolve)
- [O Que Você Ganha](#o-que-você-ganha)
- [Visão Geral](#visão-geral)
- [Início Rápido](#início-rápido)
- [Pré-requisitos](#pré-requisitos)
- [Convenções do Repositório](#convenções-do-repositório)
- [Como Referenciar os Módulos](#como-referenciar-os-módulos)
- [Ordem Recomendada de Composição](#ordem-recomendada-de-composição)
- [Exemplo de Stack Completa](#exemplo-de-stack-completa)
- [Módulos](#módulos)
  - [vpc](#módulo-vpc)
  - [nat_instance](#módulo-nat_instance)
  - [vpc_endpoints](#módulo-vpc_endpoints)
  - [alb](#módulo-alb)
  - [ecs_cluster](#módulo-ecs_cluster)
  - [ecr](#módulo-ecr)
  - [dynamodb](#módulo-dynamodb)
  - [ecs](#módulo-ecs)
  - [ecs_schedule](#módulo-ecs_schedule)
  - [cognito](#módulo-cognito)
  - [api_gateway](#módulo-api_gateway)
  - [cloudfront](#módulo-cloudfront)
  - [budget](#módulo-budget)
- [Validação dos Módulos](#validação-dos-módulos)
- [Versionamento e Publicação](#versionamento-e-publicação)

## Por Que Este Projeto Existe

Construir uma stack AWS moderna envolve dezenas de decisões de rede, segurança, observabilidade, deploy e custos.  
Sem módulos bem definidos, cada time resolve isso de um jeito diferente, gerando retrabalho e ambientes inconsistentes.

Este projeto existe para transformar essa complexidade em um catálogo de módulos composáveis, padronizados e prontos para produção.

## Problemas Que Resolve

- Entrega lenta por repetir a mesma infraestrutura em cada repositório
- Divergência entre ambientes (`dev`, `stg`, `prd`) por falta de padrão
- Alto risco de regressão ao copiar e adaptar código Terraform manualmente
- Dificuldade para evoluir arquitetura sem quebrar stacks existentes
- Onboarding demorado de novos times por falta de referência única

## O Que Você Ganha

- Provisionamento mais rápido com módulos reutilizáveis e contratos claros de input/output
- Consistência entre projetos com convenções de naming e tagging
- Evolução controlada via versionamento por tags (`ref=vX.Y.Z`)
- Menos carga operacional e mais foco no produto, não na infraestrutura base

## Visão Geral

Este repositório concentra módulos Terraform para montar uma stack AWS completa (rede, compute, dados, autenticação, entrega e custos) com componentes pequenos e reutilizáveis.

Cada módulo segue a estrutura:

- `main.tf`: recursos e lógica principal
- `variables.tf`: inputs do módulo
- `outputs.tf`: valores exportados
- `versions.tf`: versões mínimas de Terraform/providers

Contrato base esperado na maioria dos módulos:

- `project_name` e `environment` como identificadores de contexto
- `tags` como `map(string)` para padronização
- `terraform >= 1.3` e `hashicorp/aws ~> 5.0`

## Início Rápido

1. Referencie o módulo com uma tag estável (`ref=vX.Y.Z`).
2. Execute `terraform init` e `terraform plan` no repositório consumidor.
3. Em mudanças neste repositório, rode `terraform fmt` e `terraform validate` antes de publicar.

Exemplo mínimo de consumo:

```hcl
module "vpc" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/vpc?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"

  azs = ["us-east-1a", "us-east-1b"]
}
```

## Pré-requisitos

- Terraform `>= 1.3`
- Provider AWS `~> 5.0`
- Credenciais AWS com permissões para os serviços utilizados (VPC, ECS, ECR, ALB, API Gateway, Cognito, CloudFront, DynamoDB, WAF, Budgets etc.)

Exemplo de provider no repositório consumidor:

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

provider "aws" {
  region = var.aws_region
}
```

## Convenções do Repositório

- Nome padrão AWS: `${var.project_name}-${var.environment}-<suffix>`
- Nome padrão DynamoDB: `${var.project_name}_${var.environment}_<suffix>`
- Evite hardcode de conta/região/ambiente nos consumidores

Importante: existe uso misto de `environment == "prd"` e `environment == "prod"` em módulos diferentes. Defina um padrão no repositório consumidor para evitar comportamento inesperado.

## Como Referenciar os Módulos

### Desenvolvimento local

```hcl
module "vpc" {
  source       = "../../ioc-terraform-modules/modules/vpc"
  project_name = "myproject"
  environment  = "dev"

  azs = ["us-east-1a", "us-east-1b"]
}
```

### Produção (recomendado, via tag estável)

```hcl
module "vpc" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/vpc?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"

  azs = ["us-east-1a", "us-east-1b"]
}
```

### Branch específica (somente desenvolvimento)

```hcl
module "vpc" {
  source = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/vpc?ref=main"
  # ...
}
```

## Ordem Recomendada de Composição

1. `vpc`
2. `nat_instance` (se quiser saída para internet de subnets privadas via NAT instance)
3. `vpc_endpoints` (opcional, para tráfego privado a serviços AWS)
4. `alb`
5. `ecs_cluster`
6. `ecr`
7. `dynamodb`
8. `ecs`
9. `ecs_schedule` (opcional)
10. `cognito`
11. `api_gateway`
12. `cloudfront`
13. `budget`

## Exemplo de Stack Completa

Exemplo simplificado de composição entre módulos:

```hcl
locals {
  common_tags = {
    Project     = "myproject"
    Environment = "prd"
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/vpc?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"

  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  tags                 = local.common_tags
}

module "alb" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/alb?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  tags       = local.common_tags
}

module "ecs_cluster" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/ecs_cluster?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"
  tags         = local.common_tags
}

module "ecr" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/ecr?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"
  tags         = local.common_tags
}

module "dynamodb" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/dynamodb?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"

  tables = {
    users = {
      hash_key   = "user_id"
      attributes = [{ name = "user_id", type = "S" }]
    }
  }

  tags = local.common_tags
}

module "ecs" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/ecs?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"

  cluster_arn           = module.ecs_cluster.cluster_arn
  cluster_name          = module.ecs_cluster.cluster_name
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_listener_arn      = module.alb.listener_arn
  alb_security_group_id = module.alb.security_group_id
  vpc_id                = module.vpc.vpc_id

  container_image = "${module.ecr.repository_url}:latest"
  app_port        = 3000
  aws_region      = "us-east-1"

  environment_variables = {
    NODE_ENV = "production"
  }

  tags = local.common_tags
}

module "cognito" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/cognito?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"

  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret
  callback_urls        = ["https://app.exemplo.com/callback"]
  logout_urls          = ["https://app.exemplo.com/logout"]
  tags                 = local.common_tags
}

module "api_gateway" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/api_gateway?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"

  cognito_issuer        = module.cognito.issuer_url
  cognito_client_id     = module.cognito.client_id
  alb_listener_arn      = module.alb.listener_arn
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_security_group_id = module.alb.security_group_id
  cors_allowed_origins  = ["https://app.exemplo.com"]

  enable_waf     = true
  waf_rate_limit = 2000
  tags           = local.common_tags
}

module "cloudfront" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/cloudfront?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"

  aliases             = ["app.exemplo.com"]
  acm_certificate_arn = var.us_east_1_certificate_arn
  tags                = local.common_tags
}

module "budget" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/budget?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"

  daily_limit_usd = 30
  alert_email     = "finops@exemplo.com"
  tags            = local.common_tags
}
```

## Módulos

### Módulo `vpc`

Cria VPC, subnets públicas/privadas, internet gateway e route tables.

**Inputs**

| Nome | Tipo | Obrigatório | Default | Descrição |
|---|---|---|---|---|
| `project_name` | `string` | Sim | - | Prefixo de nomes |
| `environment` | `string` | Sim | - | Ambiente (`dev`, `prd`, etc.) |
| `cidr_block` | `string` | Não | `10.0.0.0/16` | CIDR da VPC |
| `azs` | `list(string)` | Sim | - | AZs usadas para subnets |
| `public_subnet_cidrs` | `list(string)` | Não | `10.0.1.0/24`, `10.0.2.0/24` | CIDRs das subnets públicas |
| `private_subnet_cidrs` | `list(string)` | Não | `10.0.10.0/24`, `10.0.11.0/24` | CIDRs das subnets privadas |
| `tags` | `map(string)` | Não | `{}` | Tags adicionais |

**Outputs**

- `vpc_id`
- `public_subnet_ids`
- `private_subnet_ids`
- `public_route_table_id`
- `private_route_table_id`

**Observações**

- Existe validação para garantir que `azs`, `public_subnet_cidrs` e `private_subnet_cidrs` tenham o mesmo tamanho.

**Exemplo**

```hcl
module "vpc" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/vpc?ref=v1.0.0"
  project_name = "myproject"
  environment  = "dev"

  azs = ["us-east-1a", "us-east-1b"]
}
```

### Módulo `nat_instance`

Cria uma NAT Instance (`t4g.nano`) com Elastic IP e rota default (`0.0.0.0/0`) na route table privada.

**Inputs**

| Nome | Tipo | Obrigatório | Default | Descrição |
|---|---|---|---|---|
| `project_name` | `string` | Sim | - | Prefixo |
| `environment` | `string` | Sim | - | Ambiente |
| `vpc_id` | `string` | Sim | - | VPC alvo |
| `public_subnet_id` | `string` | Sim | - | Subnet pública da NAT instance |
| `private_route_table_id` | `string` | Sim | - | Route table privada a ser atualizada |
| `tags` | `map(string)` | Não | `{}` | Tags |

**Outputs**

- `instance_id`
- `public_ip`

**Observações**

- Usa AMI Amazon Linux 2023 ARM64 mais recente.
- Inbound do SG da NAT está liberado para `10.0.0.0/8`.

**Exemplo**

```hcl
module "nat_instance" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/nat_instance?ref=v1.0.0"
  project_name = "myproject"
  environment  = "dev"

  vpc_id                 = module.vpc.vpc_id
  public_subnet_id       = module.vpc.public_subnet_ids[0]
  private_route_table_id = module.vpc.private_route_table_id
}
```

### Módulo `vpc_endpoints`

Cria endpoints privados para ECR API, ECR DKR, CloudWatch Logs (Interface) e S3 (Gateway).

**Inputs**

| Nome | Tipo | Obrigatório | Default | Descrição |
|---|---|---|---|---|
| `project_name` | `string` | Sim | - | Prefixo |
| `environment` | `string` | Sim | - | Ambiente |
| `aws_region` | `string` | Sim | - | Região AWS |
| `vpc_id` | `string` | Sim | - | VPC alvo |
| `private_subnet_ids` | `list(string)` | Sim | - | Subnets privadas dos endpoints interface |
| `private_route_table_ids` | `list(string)` | Sim | - | Route tables privadas do endpoint S3 |
| `allowed_cidr_blocks` | `list(string)` | Sim | - | CIDRs permitidos no SG dos endpoints |
| `tags` | `map(string)` | Não | `{}` | Tags |

**Outputs**

- `security_group_id`
- `ecr_api_endpoint_id`
- `ecr_dkr_endpoint_id`
- `logs_endpoint_id`
- `s3_endpoint_id`

**Exemplo**

```hcl
module "vpc_endpoints" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/vpc_endpoints?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"

  aws_region              = "us-east-1"
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  private_route_table_ids = [module.vpc.private_route_table_id]
  allowed_cidr_blocks     = ["10.0.0.0/16"]
}
```

### Módulo `alb`

Cria ALB, security group, listener HTTP e listener HTTPS opcional.

**Inputs**

| Nome | Tipo | Obrigatório | Default | Descrição |
|---|---|---|---|---|
| `project_name` | `string` | Sim | - | Prefixo |
| `environment` | `string` | Sim | - | Ambiente |
| `vpc_id` | `string` | Sim | - | VPC alvo |
| `subnet_ids` | `list(string)` | Não | `[]` | Subnets do ALB (recomendado) |
| `public_subnet_ids` | `list(string)` | Não | `[]` | **Deprecado**, use `subnet_ids` |
| `internal` | `bool` | Não | `false` | Se `true`, ALB interno |
| `certificate_arn` | `string` | Não | `""` | ARN do ACM para HTTPS |
| `tags` | `map(string)` | Não | `{}` | Tags |

**Outputs**

- `alb_arn`
- `alb_dns_name`
- `security_group_id`
- `http_listener_arn`
- `https_listener_arn`
- `listener_arn` (listener ativo: HTTPS quando há certificado, senão HTTP)

**Observações**

- Exige no mínimo 2 subnets (`precondition`).
- Sem certificado, o listener HTTP retorna `404` por padrão.
- Com certificado, HTTP redireciona para HTTPS (`301`).

**Exemplo**

```hcl
module "alb" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/alb?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"

  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnet_ids
  certificate_arn = var.acm_certificate_arn
}
```

### Módulo `ecs_cluster`

Cria ECS Cluster com capacity providers `FARGATE` e `FARGATE_SPOT`.

**Inputs**

| Nome | Tipo | Obrigatório | Default | Descrição |
|---|---|---|---|---|
| `project_name` | `string` | Sim | - | Prefixo |
| `environment` | `string` | Sim | - | Ambiente |
| `tags` | `map(string)` | Não | `{}` | Tags |

**Outputs**

- `cluster_arn`
- `cluster_name`

**Observações**

- `containerInsights` é habilitado apenas quando `environment == "prod"`.

**Exemplo**

```hcl
module "ecs_cluster" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/ecs_cluster?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"
}
```

### Módulo `ecr`

Cria repositório ECR com scan on push, criptografia AES256 e lifecycle policy.

**Inputs**

| Nome | Tipo | Obrigatório | Default | Descrição |
|---|---|---|---|---|
| `project_name` | `string` | Sim | - | Prefixo |
| `environment` | `string` | Sim | - | Ambiente |
| `image_count_to_keep` | `number` | Não | `3` | Quantidade de imagens mais recentes mantidas |
| `tags` | `map(string)` | Não | `{}` | Tags |

**Outputs**

- `repository_url`
- `repository_arn`

**Observações**

- Em `prd`, repositório fica `IMMUTABLE`.
- Em `dev`, `force_delete = true`.

**Exemplo**

```hcl
module "ecr" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/ecr?ref=v1.0.0"
  project_name = "myproject"
  environment  = "dev"
}
```

### Módulo `dynamodb`

Cria múltiplas tabelas DynamoDB a partir de um mapa (`tables`), com suporte a GSI, LSI, TTL, stream, PITR, SSE e tags por tabela.

**Inputs**

| Nome | Tipo | Obrigatório | Default | Descrição |
|---|---|---|---|---|
| `project_name` | `string` | Sim | - | Prefixo de tabela |
| `environment` | `string` | Sim | - | Ambiente |
| `tables` | `map(object(...))` | Sim | - | Definições de tabelas |
| `tags` | `map(string)` | Não | `{}` | Tags padrão |

Estrutura principal de `tables`:

- `hash_key` (obrigatório)
- `range_key` (opcional)
- `attributes` (obrigatório)
- `billing_mode` (opcional, default `PAY_PER_REQUEST`)
- `read_capacity`/`write_capacity` (obrigatórios quando `billing_mode = PROVISIONED`)
- `global_secondary_indexes` (opcional)
- `local_secondary_indexes` (opcional)
- `ttl` (opcional)
- `stream` (opcional; se `enabled = true`, `view_type` é obrigatório)
- `table_class`, `deletion_protection_enabled`, `point_in_time_recovery_enabled`, `server_side_encryption_enabled`, `tags`

**Outputs**

- `table_names` (mapa chave lógica -> nome físico)
- `table_arns` (mapa chave lógica -> arn)

**Observações**

- Nome final da tabela: `${project_name}_${environment}_${table_key}`.
- `deletion_protection_enabled` por padrão é `true` apenas em `environment == "prd"`.
- PITR e SSE vêm habilitados por padrão.

**Exemplo**

```hcl
module "dynamodb" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/dynamodb?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"

  tables = {
    users = {
      hash_key   = "user_id"
      attributes = [{ name = "user_id", type = "S" }]

      global_secondary_indexes = [
        {
          name            = "gsi_email"
          hash_key        = "email"
          projection_type = "ALL"
        }
      ]
    }
  }
}
```

### Módulo `ecs`

Cria serviço ECS Fargate com task definition, IAM roles, CloudWatch Logs, security group, target group e rule no listener do ALB.

**Inputs**

| Nome | Tipo | Obrigatório | Default | Descrição |
|---|---|---|---|---|
| `project_name` | `string` | Sim | - | Prefixo |
| `environment` | `string` | Sim | - | Ambiente |
| `cluster_arn` | `string` | Sim | - | ARN do ECS cluster |
| `cluster_name` | `string` | Sim | - | Nome do ECS cluster |
| `private_subnet_ids` | `list(string)` | Sim | - | Subnets privadas da task |
| `alb_listener_arn` | `string` | Sim | - | ARN do listener do ALB |
| `alb_security_group_id` | `string` | Sim | - | SG do ALB |
| `vpc_id` | `string` | Sim | - | VPC alvo |
| `container_image` | `string` | Sim | - | URI completa da imagem |
| `app_port` | `number` | Sim | - | Porta da aplicação |
| `aws_region` | `string` | Sim | - | Região AWS |
| `cpu` | `number` | Não | `256` | CPU da task Fargate |
| `memory` | `number` | Não | `512` | Memória da task |
| `use_spot_only` | `bool` | Não | `false` | Só FARGATE_SPOT quando `true` |
| `environment_variables` | `map(string)` | Não | `{}` | Vars de ambiente do container |
| `health_check_path` | `string` | Não | `/health` | Path de health check do target group |
| `alb_listener_priority` | `number` | Não | `100` | Prioridade da rule no listener |
| `log_retention_days` | `number` | Não | `7` | Retenção de logs |
| `health_check_grace_period_seconds` | `number` | Não | `60` | Grace period para health check |
| `tags` | `map(string)` | Não | `{}` | Tags |

**Outputs**

- `service_name`
- `task_definition_arn`
- `security_group_id`

**Observações**

- Cria policy IAM com acesso a tabelas DynamoDB `arn:aws:dynamodb:${aws_region}:*:table/${project_name}_${environment}_*`.
- Listener rule usa `path_pattern = ["/*"]` (atenção à prioridade se houver múltiplos serviços).
- `desired_count` e `task_definition` ficam em `ignore_changes`.

**Exemplo**

```hcl
module "ecs" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/ecs?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"

  cluster_arn           = module.ecs_cluster.cluster_arn
  cluster_name          = module.ecs_cluster.cluster_name
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_listener_arn      = module.alb.listener_arn
  alb_security_group_id = module.alb.security_group_id
  vpc_id                = module.vpc.vpc_id

  container_image = "${module.ecr.repository_url}:latest"
  app_port        = 3000
  aws_region      = "us-east-1"
}
```

### Módulo `ecs_schedule`

Cria agendamentos no EventBridge Scheduler para reduzir/aumentar `desired_count` de um ECS Service.

**Inputs**

| Nome | Tipo | Obrigatório | Default | Descrição |
|---|---|---|---|---|
| `project_name` | `string` | Sim | - | Prefixo |
| `environment` | `string` | Sim | - | Ambiente |
| `cluster_name` | `string` | Sim | - | Nome do cluster ECS |
| `service_name` | `string` | Sim | - | Nome do serviço ECS |
| `aws_region` | `string` | Sim | - | Região AWS |
| `stop_cron` | `string` | Não | `cron(0 22 * * ? *)` | Cron UTC para reduzir |
| `start_cron` | `string` | Não | `cron(0 8 * * ? *)` | Cron UTC para aumentar |
| `scale_down_count` | `number` | Não | `0` | Desired count no horário de parada |
| `scale_up_count` | `number` | Não | `1` | Desired count no horário de subida |
| `tags` | `map(string)` | Não | `{}` | Tags |

**Outputs**

- `scheduler_role_arn`

**Exemplo**

```hcl
module "ecs_schedule" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/ecs_schedule?ref=v1.0.0"
  project_name = "myproject"
  environment  = "dev"

  cluster_name = module.ecs_cluster.cluster_name
  service_name = module.ecs.service_name
  aws_region   = "us-east-1"

  stop_cron  = "cron(0 22 * * ? *)"
  start_cron = "cron(0 8 * * ? *)"
}
```

### Módulo `cognito`

Cria User Pool, domínio Cognito Hosted UI, app client OAuth e provedor Google opcional.

**Inputs**

| Nome | Tipo | Obrigatório | Default | Descrição |
|---|---|---|---|---|
| `project_name` | `string` | Sim | - | Prefixo |
| `environment` | `string` | Sim | - | Ambiente |
| `google_client_id` | `string` | Sim | - | Client ID Google OAuth (`sensitive`) |
| `google_client_secret` | `string` | Sim | - | Client Secret Google OAuth (`sensitive`) |
| `callback_urls` | `list(string)` | Sim | - | URLs de callback OAuth |
| `logout_urls` | `list(string)` | Sim | - | URLs de logout OAuth |
| `tags` | `map(string)` | Não | `{}` | Tags |

**Outputs**

- `user_pool_id`
- `user_pool_arn`
- `client_id`
- `issuer_url`

**Observações**

- Para desabilitar Google provider, passe `google_client_id = ""` e `google_client_secret = ""`.
- Em `prd` o fluxo `ALLOW_USER_PASSWORD_AUTH` é removido; em outros ambientes é mantido.

**Exemplo**

```hcl
module "cognito" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/cognito?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"

  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret
  callback_urls        = ["https://app.exemplo.com/callback"]
  logout_urls          = ["https://app.exemplo.com/logout"]
}
```

### Módulo `api_gateway`

Cria API Gateway HTTP API com:

- integração `HTTP_PROXY` para listener do ALB via `VPC_LINK`
- authorizer JWT do Cognito
- rotas públicas (`/auth/*`, `/webhooks/*`, `/health`) e rota protegida (`/{proxy+}`)
- WAF opcional

**Inputs**

| Nome | Tipo | Obrigatório | Default | Descrição |
|---|---|---|---|---|
| `project_name` | `string` | Sim | - | Prefixo |
| `environment` | `string` | Sim | - | Ambiente |
| `cognito_issuer` | `string` | Sim | - | Issuer URL do Cognito |
| `cognito_client_id` | `string` | Sim | - | Client ID do app Cognito |
| `alb_listener_arn` | `string` | Sim | - | Listener ARN usado na integração |
| `vpc_id` | `string` | Sim | - | VPC alvo |
| `private_subnet_ids` | `list(string)` | Sim | - | Subnets privadas para VPC link |
| `alb_security_group_id` | `string` | Não | `""` | SG do VPC link (recomendado) |
| `ecs_security_group_id` | `string` | Não | `""` | **Deprecado**, fallback para compatibilidade |
| `cors_allowed_origins` | `list(string)` | Sim | - | Origins permitidas no CORS |
| `enable_waf` | `bool` | Não | `false` | Habilita Web ACL |
| `waf_rate_limit` | `number` | Não | `2000` | Limite por IP em 5 minutos |
| `tags` | `map(string)` | Não | `{}` | Tags |

**Outputs**

- `api_endpoint`
- `api_id`

**Observações**

- Obrigatório informar `alb_security_group_id` (ou `ecs_security_group_id` legado).
- Em produção, evite `cors_allowed_origins = ["*"]`.

**Exemplo**

```hcl
module "api_gateway" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/api_gateway?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"

  cognito_issuer        = module.cognito.issuer_url
  cognito_client_id     = module.cognito.client_id
  alb_listener_arn      = module.alb.listener_arn
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_security_group_id = module.alb.security_group_id
  cors_allowed_origins  = ["https://app.exemplo.com"]

  enable_waf = true
}
```

### Módulo `cloudfront`

Cria bucket S3 privado + distribuição CloudFront com OAC para frontend estático/SPA.

**Inputs**

| Nome | Tipo | Obrigatório | Default | Descrição |
|---|---|---|---|---|
| `project_name` | `string` | Sim | - | Prefixo |
| `environment` | `string` | Sim | - | Ambiente |
| `price_class` | `string` | Não | `PriceClass_100` | Escopo geográfico de edge locations |
| `aliases` | `list(string)` | Não | `[]` | Domínios customizados |
| `acm_certificate_arn` | `string` | Não | `""` | Certificado ACM para aliases |
| `tags` | `map(string)` | Não | `{}` | Tags |

**Outputs**

- `bucket_name`
- `distribution_id`
- `distribution_domain`

**Observações**

- Se usar `aliases`, informe `acm_certificate_arn`.
- Certificado para CloudFront deve estar em `us-east-1`.
- Possui fallback SPA (`403/404 -> /index.html`).

**Exemplo**

```hcl
module "cloudfront" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/cloudfront?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"

  aliases             = ["app.exemplo.com"]
  acm_certificate_arn = var.us_east_1_certificate_arn
}
```

### Módulo `budget`

Cria um orçamento diário de custo com alertas em 80% e 100%.

**Inputs**

| Nome | Tipo | Obrigatório | Default | Descrição |
|---|---|---|---|---|
| `project_name` | `string` | Sim | - | Prefixo |
| `environment` | `string` | Sim | - | Ambiente |
| `daily_limit_usd` | `number` | Sim | - | Limite diário em USD |
| `alert_email` | `string` | Sim | - | E-mail para notificações |
| `tags` | `map(string)` | Não | `{}` | Tags |

**Outputs**

- `budget_name`

**Exemplo**

```hcl
module "budget" {
  source       = "git::https://github.com/thomascristanis/ioc-terraform-modules.git//modules/budget?ref=v1.0.0"
  project_name = "myproject"
  environment  = "prd"

  daily_limit_usd = 50
  alert_email     = "finops@exemplo.com"
}
```

## Validação dos Módulos

No root do repositório:

```bash
terraform fmt -check -recursive
```

Para validar um módulo específico:

```bash
cd modules/<module_name>
terraform init
terraform validate
```

Exemplo:

```bash
cd modules/ecs
terraform init
terraform validate
```

## Versionamento e Publicação

- Use tags semânticas (`vX.Y.Z`) para releases públicas estáveis.
- Em ambientes produtivos, fixe sempre o `ref` da tag no `source` do módulo.
- Em PRs, documente mudanças de variáveis/outputs e impacto de compatibilidade.
