terraform {
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

# ---------------------------------------------------------------------------
# 1a. count: one IAM user per item in a LIST, tracked by index [0], [1], [2]
#     (remove the middle name and re-apply, watch the plan shift the others)
# ---------------------------------------------------------------------------
resource "aws_iam_user" "count_example" {
  count         = length(var.count_users)
  name          = var.count_users[count.index]
  force_destroy = true

  tags = {
    CreatedWith = "count"
  }
}

# ---------------------------------------------------------------------------
# 1b. for_each: one IAM user per entry in a MAP, tracked by key ["alice"]
#     (remove one entry and re-apply, only that one user is destroyed)
# ---------------------------------------------------------------------------
resource "aws_iam_user" "example" {
  for_each      = var.users
  name          = each.key
  force_destroy = true

  tags = {
    CreatedWith = "for_each"
    Department  = each.value.department
  }
}

# ---------------------------------------------------------------------------
# 2. for expression feeding for_each: one IAM group per unique department,
#    derived from var.users (add a user with a new department and a new
#    group appears automatically)
# ---------------------------------------------------------------------------
locals {
  departments = toset([for user in values(var.users) : user.department])
}

resource "aws_iam_group" "department" {
  for_each = local.departments
  name     = "day10-${each.key}"
}

resource "aws_iam_user_group_membership" "example" {
  for_each = var.users
  user     = aws_iam_user.example[each.key].name
  groups   = [aws_iam_group.department[each.value.department].name]
}

# ---------------------------------------------------------------------------
# 3. conditionals:
#    - count = bool ? 1 : 0 turns the whole resource on or off
#    - a ternary picks the retention period based on environment
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "audit" {
  count             = var.enable_audit_logs ? 1 : 0
  name              = "/day10/${var.environment}/audit"
  retention_in_days = var.environment == "production" ? 90 : 7

  tags = {
    Environment = var.environment
  }
}
