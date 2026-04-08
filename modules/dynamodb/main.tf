locals {
  prefix = "${var.project_name}_${var.environment}"
}

# liber_users — user profiles with Identity Indirection
resource "aws_dynamodb_table" "users" {
  name         = "${local.prefix}_users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  tags         = var.tags

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "apid" # authProviderId
    type = "S"
  }

  global_secondary_index {
    name            = "auth-provider-index"
    projection_type = "KEYS_ONLY"

    key_schema {
      attribute_name = "apid"
      key_type       = "HASH"
    }
  }
}

# liber_books — shared ISBN/bookId metadata cache
resource "aws_dynamodb_table" "books" {
  name         = "${local.prefix}_books"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "bookId"
  tags         = var.tags

  attribute {
    name = "bookId"
    type = "S"
  }
}

# liber_subscriptions — SaaS plans with Payment Provider Indirection
resource "aws_dynamodb_table" "subscriptions" {
  name         = "${local.prefix}_subscriptions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  tags         = var.tags

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "provCustId"
    type = "S"
  }

  global_secondary_index {
    name            = "provider-index"
    projection_type = "KEYS_ONLY"

    key_schema {
      attribute_name = "provCustId"
      key_type       = "HASH"
    }
  }
}

# liber_spaces — physical library spaces per user
resource "aws_dynamodb_table" "spaces" {
  name         = "${local.prefix}_spaces"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "spaceId"
  tags         = var.tags

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "spaceId"
    type = "S"
  }
}

# liber_catalog — personal book collection
resource "aws_dynamodb_table" "catalog" {
  name         = "${local.prefix}_catalog"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "bookId"
  tags         = var.tags

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "bookId"
    type = "S"
  }

  attribute {
    name = "sp" # spaceId as attribute
    type = "S"
  }

  global_secondary_index {
    name            = "bookId-index"
    projection_type = "KEYS_ONLY"

    key_schema {
      attribute_name = "bookId"
      key_type       = "HASH"
    }
  }

  global_secondary_index {
    name               = "space-index"
    projection_type    = "INCLUDE"
    non_key_attributes = ["bookId"]

    key_schema {
      attribute_name = "userId"
      key_type       = "HASH"
    }

    key_schema {
      attribute_name = "sp"
      key_type       = "RANGE"
    }
  }
}

# liber_tracker — reading progress tracker
resource "aws_dynamodb_table" "tracker" {
  name         = "${local.prefix}_tracker"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "bookId"
  tags         = var.tags

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "bookId"
    type = "S"
  }

  attribute {
    name = "s" # status
    type = "S"
  }

  global_secondary_index {
    name               = "status-index"
    projection_type    = "INCLUDE"
    non_key_attributes = ["bookId", "cp", "tp", "pg"]

    key_schema {
      attribute_name = "userId"
      key_type       = "HASH"
    }

    key_schema {
      attribute_name = "s"
      key_type       = "RANGE"
    }
  }
}

# liber_library_access — read-only library sharing
resource "aws_dynamodb_table" "library_access" {
  name         = "${local.prefix}_library_access"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ownerId"
  range_key    = "guestUserId"
  tags         = var.tags

  attribute {
    name = "ownerId"
    type = "S"
  }

  attribute {
    name = "guestUserId"
    type = "S"
  }

  # TTL: pending invites expire automatically after 30 days (set by application)
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  global_secondary_index {
    name            = "guest-index"
    projection_type = "KEYS_ONLY"

    key_schema {
      attribute_name = "guestUserId"
      key_type       = "HASH"
    }
  }
}

# liber_rate_limits — distributed rate limiting counters (50 req/min per user)
resource "aws_dynamodb_table" "rate_limits" {
  name         = "${local.prefix}_rate_limits"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId" # value written by app: "<userId>:<minuteBucket>" (composite rate-limit key)
  tags         = var.tags

  attribute {
    name = "userId"
    type = "S"
  }

  # TTL: counters expire at end of each minute bucket (set by application)
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}
