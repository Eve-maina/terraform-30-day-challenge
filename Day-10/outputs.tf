# ---------------------------------------------------------------------------
# count: show which name sits at which index, so the shift is visible
# ---------------------------------------------------------------------------
output "count_users_by_index" {
  description = "Index -> username for the count-based users"
  value       = { for i, user in aws_iam_user.count_example : i => user.name }
}

# ---------------------------------------------------------------------------
# for expression: reshape the for_each resource into username -> ARN
# ---------------------------------------------------------------------------
output "user_arns" {
  description = "Map of username to IAM user ARN"
  value       = { for name, user in aws_iam_user.example : name => user.arn }
}

# for expression with grouping (...): department -> list of usernames
output "users_by_department" {
  description = "Usernames grouped by department"
  value       = { for name, user in var.users : user.department => name... }
}

# for expression with a filter (if): only engineering users, uppercased
output "engineers_uppercase" {
  description = "Engineering usernames in uppercase, shows a filtered list for expression"
  value       = [for name, user in var.users : upper(name) if user.department == "engineering"]
}

output "department_groups" {
  description = "IAM groups created from the unique departments"
  value       = [for group in aws_iam_group.department : group.name]
}

# ---------------------------------------------------------------------------
# conditionals
# ---------------------------------------------------------------------------
output "audit_log_group" {
  description = "Name of the audit log group, or a note when it is switched off"
  value       = var.enable_audit_logs ? aws_cloudwatch_log_group.audit[0].name : "disabled (enable_audit_logs = false)"
}

output "audit_log_retention_days" {
  description = "Retention the conditional picked for this environment"
  value       = var.environment == "production" ? 90 : 7
}
