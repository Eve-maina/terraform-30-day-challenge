# Day 08 - Reusable Infrastructure: Terraform Modules

## Overview

Day 7 isolated *state* per environment, but the `.tf` code itself was
still either duplicated by hand (File Layouts) or branched with a
`terraform.workspace` lookup (Workspaces). Day 8 asks the next question:
how do you stop copy-pasting the same `aws_instance` block into every
environment directory in the first place? The answer is a Terraform
**module** - the EC2 instance definition gets written once, in its own
directory, and each environment's `live` config becomes a thin caller
that just passes in the values that differ (name, size, AMI) and asks
the module to build it.

## Files

```
Day-08/
├── modules/
│   └── services/
│       └── ec2-instance/
│           ├── main.tf         - aws_instance.my_instance, the reusable
│           │                     resource definition
│           ├── variables.tf    - instance_name, ami_id, instance_type
│           └── outputs.tf      - instance_id, public_ip
├── live/
│   ├── dev/
│   │   └── services/
│   │       └── ec2_instance/
│   │           ├── main.tf     - provider, S3 backend, calls
│   │           │                 module "ec2_instance" with dev values
│   │           └── outputs.tf  - instance_id, public_ip (pass-through
│   │                             from the module's outputs)
│   └── production/
│       └── services/
│           └── ec2_instance/
│               ├── main..tf    - same shape as dev, production values
│               └── outputs.tf  - instance_id, public_ip
└── README.md              - this file / learning journal
```

The module knows nothing about "dev" or "production" - it just takes an
`instance_name`, `ami_id`, and `instance_type` and builds one
`aws_instance`. Every environment-specific decision lives in `live/`,
one directory per environment, each with its own S3 backend `key`.

## Architecture

Same minimal target as recent days - a single `aws_instance`, no custom
VPC, launched into the default VPC - but now split into two layers.
`modules/services/ec2-instance` is the reusable building block: it
declares the resource and three input variables, and exposes
`instance_id` / `public_ip` as outputs. `live/dev/services/ec2_instance`
and `live/production/services/ec2_instance` are the callers: each has
its own `provider` and `backend "s3"` block, and both `source` the same
module via a relative path (`../../../../modules/services/ec2-instance`)
while supplying their own `instance_name` (`dev_server` /
`prod_server`).

## How to Run

**Dev:**

```bash
cd live/dev/services/ec2_instance
terraform init
terraform plan
terraform apply
```

**Production:**

```bash
cd live/production/services/ec2_instance
terraform init
terraform plan
terraform apply
```

Each directory is initialized and applied independently - that's the
same "directory is the environment" idea from Day 7's File Layouts,
just now calling a shared module instead of duplicating the resource
block. To tear down, run `terraform destroy` from whichever environment
directory you applied.

---

## Learning Journal

The biggest shift today was learning to separate the module's inputs
(`variables.tf`) and outputs (`outputs.tf`) from the caller's own
`outputs.tf` - the root `output "instance_id"` in `live/dev` doesn't
read `aws_instance.my_instance.id` directly, it reads
`module.ec2_instance.instance_id`, which only exists because the module
itself published that value first. Nothing is accessible across a
module boundary unless it's explicitly declared as an output on the
inside and referenced through the module's local name on the outside.

Full write-up below.

### Blog Post

[Medium blog](https://medium.com/@eve.maina/terraform-modules-turning-copy-paste-infrastructure-into-reusable-building-blocks-0e5647d4bfb0)

---

*Tags: #30DayTerraformChallenge #TerraformChallenge #Terraform #AWS #IaC #Modules*
