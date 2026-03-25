# Day 01 — What is Infrastructure as Code?

## Overview

An introduction to Infrastructure as Code and why it exists.
The core problem with traditional cloud work: infrastructure built
by clicking through a console leaves no record, no repeatability,
and no clarity about what exists or why. Two months later, nobody
knows what security groups a server uses, why its storage is a
different size, or who gave it that curious IAM role.

Infrastructure as Code fixes this. You write a file that describes
exactly what you want. That file lives in Git. Git never forgets.

---

## Key Concepts

### Infrastructure as Code (IaC)
The practice of managing and provisioning infrastructure using code
instead of manual processes. Your configuration file becomes the
single source of truth — bringing the same discipline used in
software development (version control, peer review, repeatability)
directly into infrastructure.

### Terraform
An open source IaC tool built by HashiCorp. You describe the
infrastructure you want — VPCs, subnets, servers, databases — and
Terraform builds it. It works across AWS, GCP, Azure, and hundreds
of other providers, meaning you learn one tool and use it
everywhere. Under the hood it tracks everything it has created in a
state file, so it always knows the difference between what exists
and what you asked for.

### Declarative vs Imperative

| Approach | How it works | Problem |
|----------|-------------|---------|
| **Imperative** | Step-by-step instructions, like a recipe | No memory of previous runs — running twice can create duplicates or errors |
| **Declarative** | Describe the end state, let the tool figure out how to get there | None — this is how Terraform works |

With Terraform's declarative approach:
- Run it once → infrastructure is created
- Run it again → nothing changes, desired state already exists
- Change one thing in the config → only that one thing updates

That predictability is what makes Terraform safe to use at scale.

---

## Lab: Manual vs Terraform

Built the same multi-AZ AWS network architecture twice.

**The architecture:**
- VPC across 3 availability zones
- Public and private subnets
- Internet Gateway
- NAT Gateway + Elastic IP
- Route tables with subnet associations

**Doing it manually (~20 minutes):**
Each step depends on the last. Create the VPC, then subnets one
by one, then the Internet Gateway, attach it, create the NAT
Gateway, allocate an Elastic IP, create two route tables, associate
six subnets, add the routes. One wrong click and traffic stops
routing. Nothing is written down.

**Doing it with Terraform (~5 minutes):**
Two files. One command. The same 18 AWS resources, reproduced
perfectly without touching the console once.

That moment genuinely changed how I think about cloud work.

---

## Takeaways

- Manual infrastructure is fragile, undocumented, and impossible
  to reliably reproduce
- IaC treats infrastructure the same way developers treat code —
  reviewable, versioned, and repeatable
- Terraform's declarative model means you describe *what* you want,
  not *how* to build it
- The state file is Terraform's memory — it always knows what it
  created

---

## Start of the 30-Day Challenge

This is day one of a 30-day commitment to getting real hands-on
experience with Terraform — building actual cloud infrastructure,
breaking things, understanding why they broke, and fixing them.

The goal is not surface-level familiarity. The goal is to finish
day 30 and barely recognise how far things have come from here.

---


*Tags: #30DayTerraformChallenge #IaC #Terraform #HashiCorp #AWS*
