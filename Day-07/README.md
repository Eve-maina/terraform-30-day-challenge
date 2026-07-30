# Day 07 - State Isolation: Terraform Workspaces & File Layouts

## Overview

Day 6 solved *who* can write to state at any given moment - move it to S3,
gate every read/write with a DynamoDB lock. Day 7 asks the next question:
once state is remote and safe from concurrent writes, how do you stop dev,
staging, and production from sharing that *same* state file in the first
place? Two mechanisms answer that: Terraform Workspaces, which keep one
codebase and swap the active state file behind the scenes, and File
Layouts, which give every environment its own directory and its own
complete copy of the code. Both were built against the same target - one
EC2 instance, same AMI, sized differently per environment - so the
isolation mechanism itself could be compared honestly rather than
theoretically.

## Files

```
Day-07/
├── Workspaces/
│   ├── main.tf            - provider, S3 backend (single shared state key),
│   │                         aws_instance.web with instance_type keyed by
│   │                         terraform.workspace
│   └── variables.tf        - aws_region, ami_id, instance_type (map(string)
│                              keyed by dev/staging/production)
├── File_Layouts/
│   └── environments/
│       ├── dev/
│       │   ├── main.tf        - provider, aws_instance.web
│       │   ├── variables.tf    - aws_region, ami_id, instance_type (plain
│       │   │                     string), environment
│       │   ├── outputs.tf      - instance_id, instance_type, public_ip
│       │   └── backend.tf      - S3 backend, key = environments/dev/...
│       ├── staging/            - same four files, instance_type = t3.small
│       └── production/         - same four files, instance_type =
│                                  c7i-flex.large
└── README.md              - this file / learning journal
```

Both setups share the same S3 bucket (`kalibee-terraform-state-2026`) and
the same DynamoDB lock table (`terraform-locks`) from Day 6, but never the
same state object - that's the whole point.

## Architecture

Deliberately small on both sides: one `aws_instance.web`, same AMI
(`ami-02b64aa047cb5edf5`), no custom VPC or subnet - it launches into the
account's default VPC so the lesson stays focused on state isolation
rather than networking. The only thing that varies per environment is
`instance_type` (`t3.micro` / `t3.small` / `c7i-flex.large`) and the tags
that identify which environment an instance belongs to.

The two approaches get there differently. Workspaces keep one `main.tf`
and resolve `instance_type` through `var.instance_type[terraform.workspace]`
at apply time - the code never changes, only which workspace (and
therefore which state file) is active. File Layouts drop the map and the
`terraform.workspace` lookup entirely; each environment directory just
hardcodes its own `instance_type` default, because the directory itself
*is* the environment.

## How to Run

**Workspaces:**

```bash
cd Workspaces
terraform init
terraform workspace new dev
terraform workspace new staging
terraform workspace new production

terraform workspace select dev
terraform apply

terraform workspace select staging
terraform apply

terraform workspace select production
terraform apply

terraform workspace list
```

**File Layouts:**

```bash
cd File_Layouts/environments/dev
terraform init
terraform apply

cd ../staging
terraform init
terraform apply

cd ../production
terraform init
terraform apply
```

Confirm isolation on either side with `terraform state show aws_instance.web`
per environment, or by checking the S3 console - see the learning journal
below for what that actually looks like.

To tear down:

```bash
terraform destroy
```

(run per workspace, or per directory, same as apply)

---

## Learning Journal

Started this by rebuilding the Day 5/6 EC2 example with a full custom VPC,
subnet, internet gateway, route table, and security group per environment -
then realized that much networking scaffolding was burying the actual
lesson. Stripped it back to just the instance, relying on the account's
default VPC. That trade-off is explicit: no control over which subnet or
AZ the instance lands in, and no custom security group (SSH isn't open by
default), but the workspace/state mechanics became the whole focus instead
of getting lost in networking resources.

The part that took the longest to click: switching workspaces does not
switch *code*. There's only ever one set of `.tf` files. What
`terraform workspace select` actually changes is which state file the next
`plan`/`apply` compares against, and what `terraform.workspace` evaluates
to inside that shared code. Editing `main.tf` affects every workspace
immediately; it just doesn't take effect against a given environment's
real infrastructure until you select that workspace and apply again.

Checking the S3 bucket after both setups were applied surfaced something
worth flagging: three separate top-level entries appeared - a bare
`terraform.tfstate` (the Workspaces setup's `default` workspace), an
`env:/` folder (auto-generated by the S3 backend the moment a non-default
workspace is created - `dev`, `staging`, and `production` each get their
own subfolder under it), and an `environments/` folder (not automatic at
all - it's the literal `key` value hardcoded into each File Layout
`backend.tf`). Same bucket, two unrelated naming mechanisms, no collision.

Also worked through `terraform_remote_state` conceptually: it lets one
config read another config's published `output` values, which is how
separate state files (say, a networking layer and a compute layer within
the same environment) can still hand values to each other without being
combined into a single Terraform run. Nothing in today's architecture
publishes a remote state output yet - the natural next step would be
splitting networking out as its own layer to actually exercise this.

Full write-ups, including the honest trade-offs between the two isolation
strategies, in the blog posts below.

### Challenges and Fixes

- Initial custom VPC/subnet/security group setup added too much
  networking surface for a lesson about state isolation - simplified to
  the account's default VPC via `data "aws_vpc" "default"`, then dropped
  even that in favor of letting AWS resolve the default VPC implicitly
  with no `subnet_id` or security group specified at all.
- `instance_type` needed to differ per environment. Workspaces solved this
  with `map(string)` keyed by `terraform.workspace`; File Layouts solved
  it more simply, since each directory only ever represents one
  environment, a plain `string` default is enough.
- Assumed switching workspaces would somehow isolate code, not just
  state - it doesn't. Confirmed that a code change applies to every
  workspace's *next* apply, but not retroactively to environments you
  haven't re-applied yet.
- Saw an unexplained `env:/` folder in S3 after the Workspaces setup - it
  is not something configured; it's the S3 backend's default
  `workspace_key_prefix`, applied automatically to every non-default
  workspace.

### Blog Posts

- [One Terraform Config, Three Environments: A Practical Look at Workspaces](./terraform-workspaces-blog.md) *(draft, pending publish)*
- [State Isolation: Workspaces vs File Layouts (and When to Use Each)](./workspaces-vs-file-layouts-blog.md) *(draft, pending publish)*
- [Medium blog](https://medium.com/@eve.maina/terraform-state-isolation-explained-workspaces-file-layouts-and-where-each-breaks-19d83449dbcc)

---

*Tags: #30DayTerraformChallenge #TerraformChallenge #Terraform #AWS #IaC #StateIsolation #Workspaces #FileLayouts*
