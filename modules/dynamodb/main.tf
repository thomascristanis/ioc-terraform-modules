locals {
  prefix = "${var.project_name}_${var.environment}"

  # Backward-compatible defaults for current consumers that do not pass `tables`.
  default_tables = {
    users = {
      hash_key   = "userId"
      attributes = [{ name = "userId", type = "S" }, { name = "apid", type = "S" }]
      global_secondary_indexes = [{
        name            = "auth-provider-index"
        hash_key        = "apid"
        projection_type = "KEYS_ONLY"
      }]
    }

    books = {
      hash_key   = "bookId"
      attributes = [{ name = "bookId", type = "S" }]
    }

    subscriptions = {
      hash_key   = "userId"
      attributes = [{ name = "userId", type = "S" }, { name = "provCustId", type = "S" }]
      global_secondary_indexes = [{
        name            = "provider-index"
        hash_key        = "provCustId"
        projection_type = "KEYS_ONLY"
      }]
    }

    spaces = {
      hash_key   = "userId"
      range_key  = "spaceId"
      attributes = [{ name = "userId", type = "S" }, { name = "spaceId", type = "S" }]
    }

    catalog = {
      hash_key  = "userId"
      range_key = "bookId"
      attributes = [
        { name = "userId", type = "S" },
        { name = "bookId", type = "S" },
        { name = "sp", type = "S" }
      ]
      global_secondary_indexes = [
        {
          name            = "bookId-index"
          hash_key        = "bookId"
          projection_type = "KEYS_ONLY"
        },
        {
          name               = "space-index"
          hash_key           = "userId"
          range_key          = "sp"
          projection_type    = "INCLUDE"
          non_key_attributes = ["bookId"]
        }
      ]
    }

    tracker = {
      hash_key  = "userId"
      range_key = "bookId"
      attributes = [
        { name = "userId", type = "S" },
        { name = "bookId", type = "S" },
        { name = "s", type = "S" }
      ]
      global_secondary_indexes = [{
        name               = "status-index"
        hash_key           = "userId"
        range_key          = "s"
        projection_type    = "INCLUDE"
        non_key_attributes = ["bookId", "cp", "tp", "pg"]
      }]
    }

    library_access = {
      hash_key   = "ownerId"
      range_key  = "guestUserId"
      attributes = [{ name = "ownerId", type = "S" }, { name = "guestUserId", type = "S" }]
      ttl        = { attribute_name = "ttl", enabled = true }
      global_secondary_indexes = [{
        name            = "guest-index"
        hash_key        = "guestUserId"
        projection_type = "KEYS_ONLY"
      }]
    }

    rate_limits = {
      hash_key   = "userId"
      attributes = [{ name = "userId", type = "S" }]
      ttl        = { attribute_name = "ttl", enabled = true }
    }
  }

  tables = length(var.tables) > 0 ? var.tables : local.default_tables
}

resource "aws_dynamodb_table" "tables" {
  for_each = local.tables

  name                        = "${local.prefix}_${each.key}"
  billing_mode                = try(each.value.billing_mode, "PAY_PER_REQUEST")
  hash_key                    = each.value.hash_key
  range_key                   = try(each.value.range_key, null)
  deletion_protection_enabled = try(each.value.deletion_protection_enabled, var.environment == "prd")
  table_class                 = try(each.value.table_class, null)
  read_capacity               = try(each.value.billing_mode, "PAY_PER_REQUEST") == "PROVISIONED" ? try(each.value.read_capacity, null) : null
  write_capacity              = try(each.value.billing_mode, "PAY_PER_REQUEST") == "PROVISIONED" ? try(each.value.write_capacity, null) : null
  stream_enabled              = try(each.value.stream.enabled, false)
  stream_view_type            = try(each.value.stream.enabled, false) ? try(each.value.stream.view_type, null) : null
  tags                        = merge(var.tags, try(each.value.tags, {}))

  dynamic "attribute" {
    for_each = each.value.attributes

    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = try(each.value.global_secondary_indexes, [])

    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = try(global_secondary_index.value.range_key, null)
      projection_type = global_secondary_index.value.projection_type

      non_key_attributes = global_secondary_index.value.projection_type == "INCLUDE" ? try(global_secondary_index.value.non_key_attributes, []) : null
      read_capacity      = try(each.value.billing_mode, "PAY_PER_REQUEST") == "PROVISIONED" ? try(global_secondary_index.value.read_capacity, null) : null
      write_capacity     = try(each.value.billing_mode, "PAY_PER_REQUEST") == "PROVISIONED" ? try(global_secondary_index.value.write_capacity, null) : null
    }
  }

  dynamic "local_secondary_index" {
    for_each = try(each.value.local_secondary_indexes, [])

    content {
      name            = local_secondary_index.value.name
      range_key       = local_secondary_index.value.range_key
      projection_type = local_secondary_index.value.projection_type

      non_key_attributes = local_secondary_index.value.projection_type == "INCLUDE" ? try(local_secondary_index.value.non_key_attributes, []) : null
    }
  }

  dynamic "ttl" {
    for_each = try(each.value.ttl, null) == null ? [] : [each.value.ttl]

    content {
      attribute_name = ttl.value.attribute_name
      enabled        = try(ttl.value.enabled, true)
    }
  }

  point_in_time_recovery {
    enabled = try(each.value.point_in_time_recovery_enabled, true)
  }

  server_side_encryption {
    enabled = try(each.value.server_side_encryption_enabled, true)
  }

  lifecycle {
    precondition {
      condition     = try(each.value.billing_mode, "PAY_PER_REQUEST") != "PROVISIONED" || (try(each.value.read_capacity, null) != null && try(each.value.write_capacity, null) != null)
      error_message = "read_capacity and write_capacity are required when billing_mode is PROVISIONED."
    }

    precondition {
      condition     = !try(each.value.stream.enabled, false) || try(each.value.stream.view_type, null) != null
      error_message = "stream.view_type is required when stream.enabled is true."
    }
  }
}
