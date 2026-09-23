# Day 10: count, for_each, for expressions, conditionals

Three files, each one showing a different part of today's lesson.

- `variables.tf`: the inputs you can flip
- `main.tf`: the actual resources
- `outputs.tf`: the values you get back after apply

## Why not count for the IAM users?

`count` tracks resources by their position in a list (`aws_iam_user.count_example[0]`, `[1]`, `[2]`). If you delete an item from the middle of the list, every item after it moves up one position. Terraform sees those new indexes and plans to change or destroy resources you never meant to touch. For example, removing `erin` from `["dave", "erin", "frank"]` makes Terraform rename `[1]` from erin to frank and destroy `[2]`, so the original frank user is deleted even though you only asked to remove erin.

`for_each` tracks each resource by a key instead (`aws_iam_user.example["alice"]`). Keys do not depend on order, so removing `bob` destroys only `bob`. Adding or reordering entries leaves the others alone.

In short: use `count` for "how many copies" or to switch a resource on and off (`0` or `1`). Use `for_each` when each resource has its own identity.

This project creates both kinds of users side by side, so you can watch the difference happen in your own plan.

## What each resource demonstrates

**`aws_iam_user.count_example`** uses `count` over `var.count_users` (a list). This is the "wrong way" on purpose. The `count_users_by_index` output shows which name sits at which index.

**`aws_iam_user.example`** uses `for_each` over `var.users` (a map). This is the fix. Each user is tracked by its username, so nothing shifts.

**`aws_iam_group.department`** uses `for_each` over a set built by a `for` expression: `toset([for user in values(var.users) : user.department])`. You never list the groups by hand. Add a user with a new department and a new group appears. **`aws_iam_user_group_membership.example`** then puts each user into their department's group, which you can see in the IAM console.

**`aws_cloudwatch_log_group.audit`** shows both conditional patterns on one real resource:
- `count = var.enable_audit_logs ? 1 : 0` switches the whole resource on or off (the same idea as `enable_autoscaling`)
- `retention_in_days = var.environment == "production" ? 90 : 7` picks a value based on the environment

**`outputs.tf`** shows the different forms of `for` expressions: map to map (`user_arns`), grouping with `...` (`users_by_department`), and filtering with `if` (`engineers_uppercase`).

## Running it

```bash
terraform init
terraform apply
```

You will need AWS credentials configured (`aws configure` or environment variables). This costs nothing: IAM users and groups are free, and an empty CloudWatch log group has no charge.

## Things to try

1. **Apply with the defaults.** Look at the outputs and open IAM in the AWS console. You should see six users, two `day10-` groups, and the `/day10/dev/audit` log group in CloudWatch.

2. **See the count problem.** Remove `"erin"` from `count_users` and run `terraform plan`. Terraform wants to rename `[1]` to frank and destroy `[2]`, so it changes two users when you only removed one.

3. **See the for_each fix.** Put erin back, then remove `bob` from `users` and run `terraform plan`. Only `aws_iam_user.example["bob"]` and his group membership are destroyed. The `day10-marketing` group is also removed, because the `for` expression no longer finds that department.

4. **Add a department.** Add `dan = { department = "finance" }` to `users` and apply. A `day10-finance` group is created, and dan is added to it automatically.

5. **Toggle a resource.** Apply with `-var="enable_audit_logs=false"`. The log group is destroyed, and the `audit_log_group` output says it is disabled.

6. **Change a value by environment.** Apply with `-var="environment=production"`. The log group is replaced with `/day10/production/audit`, and its retention changes from 7 to 90 days.

## Cleaning up

```bash
terraform destroy
```
