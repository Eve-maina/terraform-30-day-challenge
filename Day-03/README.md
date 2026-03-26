# Day 03 — Deploying Your First Server with Terraform

## Overview

Day 3 is where things got real. After two days of setup and theory,
today was about actually deploying infrastructure. Using Terraform,
I provisioned a web server on AWS EC2 from scratch — no console
clicking, just code.

By the end of this lab a real server was running on AWS, accessible
from a browser, and provisioned entirely through Terraform.

---

## What Was Built

- A security group allowing HTTP traffic on port 80
- An EC2 instance running Amazon Linux 2
- A user data script that installs Apache and serves a basic HTML page
- An output that prints the server's public IP after deployment

---

## Files
```
Day-03/
├── main.tf       — provider, security group, EC2 instance, output
└── README.md     — this file
```

---

## Prerequisites

- Terraform installed
- AWS CLI installed and configured with IAM credentials
- VS Code with the HashiCorp Terraform extension

---

## How to Use

**1. Clone the repo and navigate to this folder**
```bash
cd Day-03
```

**2. Find the correct AMI ID for your region**
```bash
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --region eu-west-1 \
  --output text
```

**3. Check your free tier eligible instance types**
```bash
aws ec2 describe-instance-types \
  --filters "Name=free-tier-eligible,Values=true" \
  --query "InstanceTypes[*].InstanceType" \
  --region eu-west-1 \
  --output text
```

**4. Update main.tf with your AMI ID and instance type**

**5. Initialise Terraform**
```bash
terraform init
```

**6. Preview the changes**
```bash
terraform plan
```

**7. Deploy**
```bash
terraform apply
```

**8. Verify — paste the output public IP into your browser**

**9. Clean up**
```bash
terraform destroy
```

---

## Key Concepts Covered

- The difference between the terraform block, provider block,
  and resource block
- What an AMI is and why AMI IDs are region specific
- How the security group and EC2 instance resources reference
  each other
- How user data scripts work on first boot
- The full Terraform workflow — init, plan, apply, destroy

---

## Lessons Learned

- AMI IDs are region specific — never copy one from a tutorial
  without verifying it exists in your region
- Always check which instance types are eligible before deploying
- The output block saves you from hunting for your server's IP
  in the AWS console
- Always run terraform destroy after finishing a lab

---

## Blog Post

[Read blog here](https://medium.com/@eve.maina/deploying-your-first-server-with-terraform-a-beginners-guide-7bef1385aa65)
