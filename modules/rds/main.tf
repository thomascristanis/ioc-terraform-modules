locals {
  name    = "${var.project_name}-${var.environment}"
  is_prod = var.environment == "prd"

  # Per-environment defaults, each overridable via its variable.
  # Note: Multi-AZ is disabled by default even in prd for this platform.
  multi_az                = var.multi_az != null ? var.multi_az : false
  deletion_protection     = var.deletion_protection != null ? var.deletion_protection : local.is_prod
  backup_retention_period = var.backup_retention_period != null ? var.backup_retention_period : (local.is_prod ? 7 : 1)
  skip_final_snapshot     = var.skip_final_snapshot != null ? var.skip_final_snapshot : !local.is_prod

  instance_class = var.instance_class != "" ? var.instance_class : (local.is_prod ? "db.t4g.small" : "db.t4g.micro")
}

# --- Master credentials (generated, stored in Secrets Manager) ---

resource "random_password" "master" {
  length  = 32
  special = false
}

# Stable suffix so the final snapshot id is unique across recreations
# without drifting on every plan (unlike timestamp()).
resource "random_id" "snapshot_suffix" {
  byte_length = 4
}

resource "aws_secretsmanager_secret" "db" {
  name        = "${local.name}-rds-credentials"
  description = "PostgreSQL master credentials for ${local.name}"

  # In non-prd, recreate immediately instead of waiting out the recovery
  # window, so frequent destroy/apply cycles don't collide on the secret name.
  recovery_window_in_days = local.is_prod ? 30 : 0

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = var.port
    dbname   = var.database_name
  })
}

# --- Security Group ---

resource "aws_security_group" "db" {
  name        = "${local.name}-rds"
  description = "Allow PostgreSQL inbound traffic to RDS"
  vpc_id      = var.vpc_id
  tags        = var.tags

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      description     = "PostgreSQL from allowed security group"
      from_port       = var.port
      to_port         = var.port
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Subnet group ---

resource "aws_db_subnet_group" "main" {
  name       = "${local.name}-rds"
  subnet_ids = var.private_subnet_ids
  tags       = var.tags

  lifecycle {
    precondition {
      condition     = length(var.private_subnet_ids) >= 2
      error_message = "Provide at least 2 private_subnet_ids spanning different AZs."
    }
  }
}

# --- Instance ---

resource "aws_db_instance" "main" {
  identifier     = "${local.name}-postgres"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = local.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  storage_encrypted     = true
  kms_key_id            = var.kms_key_id != "" ? var.kms_key_id : null

  db_name  = var.database_name
  username = var.master_username
  password = random_password.master.result
  port     = var.port

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  multi_az               = local.multi_az
  publicly_accessible    = false

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  backup_retention_period   = local.backup_retention_period
  deletion_protection       = local.deletion_protection
  skip_final_snapshot       = local.skip_final_snapshot
  final_snapshot_identifier = local.skip_final_snapshot ? null : "${local.name}-postgres-final-${random_id.snapshot_suffix.hex}"

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  tags = var.tags
}
