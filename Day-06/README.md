# Day 06 - Remote State & Locking: S3 Backend + DynamoDB

## Overview

Day 5 established that `terraform.tfstate` is Terraform's memory, not the
infrastructure itself - and that memory lived on a local disk, readable and
writable by exactly one person at a time. Day 6 asks the obvious follow-up:
what happens the moment more than one person, or process, needs to touch
that memory at once? The answer was to stop keeping state locally
altogether - move it to an S3 bucket, and make sure only one Terraform
operation can write to it at a time using a DynamoDB table as a lock.

## Files

```
Day-06/
├── main.tf              - provider, S3 backend configuration (bucket, key,
│                           region, dynamodb_table), VPC resource (aws_vpc.myvpc)
├── variables.tf          - aws_region, vpc_cidr, vpc_name
└── README.md              - this file / learning journal
```

`terraform.tfstate` no longer lives in this folder. Once the S3 backend is
configured and `terraform init` migrates state, the file lives in the
`kalibee-terraform-state-2026` S3 bucket under the key `terraform.tfstate`,
and every read/write to it is gated by a lock row in the `terraform-locks`
DynamoDB table.

## Architecture

The infrastructure itself is intentionally small - one VPC (`myvpc`) with
DNS hostnames and DNS support enabled. It isn't the point of the day; it's
the test subject for the backend migration and locking experiments below.
The real architecture being built today lives outside `main.tf` entirely:
an S3 bucket storing state, and a DynamoDB table enforcing that only one
`plan`/`apply` can hold that state at a time.

## How to Run

Bootstrap the backend once, manually, before Terraform ever runs (this
can't be done with Terraform itself - see the learning journal for why):

```bash
aws s3api create-bucket \
  --bucket kalibee-terraform-state-2026 \
  --region af-south-1 \
  --create-bucket-configuration LocationConstraint=af-south-1

aws s3api put-bucket-versioning \
  --bucket kalibee-terraform-state-2026 \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region af-south-1
```

Then, as usual:

```bash
cd Day-06
terraform init      # migrates local state into the S3 backend
terraform plan
terraform apply
```

To see locking in action, open a second terminal in the same directory and
run `terraform apply` or `terraform plan` while the first is still running.
Once you're done:

```bash
terraform destroy
```

---

## Learning Journal

The S3 bucket and DynamoDB table couldn't be created with Terraform itself
- that would mean storing the state for creating the backend somewhere that
doesn't exist yet - so both were bootstrapped once, by hand, via the AWS
CLI. After wiring up the `backend "s3"` block and running `terraform init`,
no object appeared in the bucket yet; state is only written on the first
`apply`, not on `init`. Running `apply` created the `terraform.tfstate`
object in S3 at the configured key, with DynamoDB backing every read/write
to it with a lock.

To prove the lock actually works, I ran `terraform apply` in one terminal
and `terraform plan` in another, seconds apart, against the same state.
The first process won the lock cleanly; the second failed instantly with a
`ConditionalCheckFailedException` from DynamoDB, exactly the mechanism
that keeps two concurrent operations from corrupting shared state.

Full write-up, with the mechanics of *why* this works, in the blog post
below.

### Challenges and Fixes

- The DynamoDB table's partition key must be named exactly `LockID` (type
  String) - Terraform's S3 backend looks for that attribute by name, not
  by position.
- No object appears in S3 right after `terraform init` if there was no
  prior local state and nothing has been applied yet - state is only
  written on the first `apply`, not on `init`.
- Terraform now flags `dynamodb_table` as deprecated in favor of a newer
  `use_lockfile` option that locks natively inside S3 without a separate
  table. The DynamoDB approach still works and is what this challenge
  used, but it's worth knowing the pattern is shifting.

### Blog Post

[Medium blog](https://medium.com/@eve.maina/from-local-to-locked-setting-up-remote-terraform-state-with-s3-and-dynamodb-89922a56ebe8)

---

*Tags: #30DayTerraformChallenge #TerraformChallenge #Terraform #AWS #IaC #S3 #DynamoDB*