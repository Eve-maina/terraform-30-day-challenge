# Day 09 - Module Versioning with Git Tags

## Overview

Day 8 introduced modules but the `live` configs sourced them with a plain
relative path (`../../../../modules/...`). That works for a single local
checkout, but it means every environment is always running whatever code
currently sits in the module directory - there's no way for `dev` to try
out a change while `production` stays on something known-stable. Day 9
swaps the relative path for a **versioned git source**: the module is
pushed to GitHub, each release is marked with an annotated tag
(`v0.0.1`, `v0.0.2`, `v0.0.3`...), and every `live` config's `source`
line points at a specific `?ref=<tag>` instead of "whatever's on disk
right now." The module itself also grew up from a single EC2 instance to
a full load-balanced, auto-scaling cluster.

## Files

```
Day-09/
├── modules/
│   └── services/
│       └── web-cluster/
│           ├── main.tf         - ALB, target group, launch template,
│           │                     ASG, and the two security groups
│           ├── variables.tf    - cluster_name, ami_id, vpc_id,
│           │                     subnet_ids, min_size, max_size,
│           │                     instance_type, server_port
│           ├── outputs.tf      - alb_dns_name, asg_name,
│           │                     instance_security_group_id
│           ├── user-data.sh    - installs httpd, writes a styled
│           │                     "Hello from the cloud" index.html
│           └── README.md       - module-level usage docs
├── live/
│   ├── dev/
│   │   └── services/
│   │       └── webserver-cluster/
│   │           ├── main.tf     - provider + module call,
│   │           │                 source pinned to ?ref=v0.0.3
│   │           └── outputs.tf  - pass-through outputs
│   └── prod/
│       └── services/
│           └── webserver-cluster/
│               ├── main.tf     - same shape, source pinned to
│               │                 ?ref=v0.0.2 (one version behind dev)
│               └── outputs.tf  - pass-through outputs
└── README.md               - this file / learning journal
```

## Architecture

`modules/services/web-cluster` is the reusable building block: an
Application Load Balancer with an HTTP listener, a target group with
health checks, a launch template running `user-data.sh`, an Auto Scaling
Group, and two security groups (one for the ALB, one for the instances -
kept separate so callers can attach extra ingress rules to the instance
group without touching the module). None of that knows about "dev" or
"prod" - it just takes `cluster_name`, `ami_id`, `vpc_id`, `subnet_ids`,
`min_size`/`max_size`, and builds the cluster.

The `live/` configs are the callers, and this is where Day 9's real
change lives: instead of `source = "../../../../modules/..."`, each one
sources the module straight from GitHub -

```hcl
source = "git::https://github.com/Eve-maina/terraform-30-day-challenge.git//Day-09/modules/services/web-cluster?ref=v0.0.3"
```

`dev` is pinned to `v0.0.3` (the latest tag, including the styled HTML
page). `prod` is deliberately left on `v0.0.2` until the newer version
has been validated in dev - promoting prod is then just a one-line edit
to its `ref=` and a commit, no module code changes required.

## Module Versioning

Three tags exist on this module so far:

| Tag      | What changed                                              |
|----------|-------------------------------------------------------------|
| `v0.0.1` | Initial cluster module (ALB, ASG, busybox user-data)         |
| `v0.0.2` | Switched `user-data.sh` to install real `httpd`; bumped default `instance_type` to `t3.small` |
| `v0.0.3` | `user-data.sh` now writes a styled HTML page instead of plain text |

Tags never move on their own - each one is a permanent pointer set by
hand (`git tag -a vX.Y.Z -m "..."` + `git push origin vX.Y.Z`). Editing
module code and pushing to `main` does **not** change what any existing
tag resolves to; a new tag has to be cut deliberately for a `live`
config to pick up the change via `terraform init -upgrade`.

## How to Run

**Dev:**

```bash
cd live/dev/services/webserver-cluster
terraform init -upgrade
terraform plan
terraform apply
```

**Prod:**

```bash
cd live/prod/services/webserver-cluster
terraform init -upgrade
terraform plan
terraform apply
```

The `-upgrade` flag matters whenever the `ref=` in `source` changes -
without it, Terraform may keep reusing the module copy it already
cached locally instead of re-fetching the newly tagged version. Each
directory still initializes and applies independently, same as every
day since the File Layouts split. To tear down, run `terraform destroy`
from whichever environment directory you applied.

---

## Learning Journal

The biggest shift today was realizing that a module `source` and a
module `version` aren't the same mechanism depending on where the
module comes from. A Terraform Registry module gets a separate
`version` argument; a git-sourced module has no such argument at all -
the version *is* the `ref` query parameter on the URL, and it can be a
branch (floating, not a real pin), a tag (a real version, if tags are
actually cut), or a commit SHA (the strictest pin). Pointing `ref` at
`main` isn't versioning, it's just "always latest," which defeats the
purpose of splitting `live` from `modules` in the first place.

Full write-up below.

### Blog Post

[Medium blog](https://medium.com/@eve.maina/pin-it-or-break-it-versioning-terraform-modules-the-right-way-b4f8c8e5e35a)

---

*Tags: #30DayTerraformChallenge #TerraformChallenge #Terraform #AWS #IaC #Modules #ModuleVersioning*
