# terraform-aws-webserver-cluster

A reusable Terraform module that provisions a load-balanced, auto-scaling
cluster of EC2 web server instances on AWS. It creates an Application Load
Balancer, a target group with health checks, a launch template, an Auto
Scaling Group, and the security groups needed to wire them together.

## What it creates

- An Auto Scaling Group of EC2 instances, launched from a launch template
- An Application Load Balancer (ALB) with an HTTP listener
- A target group with health checks routing traffic to the ASG
- A security group for the instances (HTTP inbound on `server_port`, all outbound)
- A security group for the ALB (HTTP inbound on port 80, all outbound)

## Usage

```hcl
module "webserver_cluster" {
  source = source = "github.com/Eve-maina/terraform-30-day-challenge//Day-09/modules/services/web-cluster?ref=v0.0.1"

  cluster_name  = "webservers-dev"
  ami_id        = "ami-0bdc7d025135d7b49"
  vpc_id        = "vpc-xxxxxxxx"
  subnet_ids    = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
  min_size      = 2
  max_size      = 4
}

output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}
```

## Inputs

| Name            | Description                                         | Type           | Default     | Required |
|-----------------|------------------------------------------------------|----------------|-------------|----------|
| `cluster_name`  | The name to use for all cluster resources             | `string`       | —           | yes      |
| `ami_id`        | AMI ID to launch cluster instances from                | `string`       | —           | yes      |
| `vpc_id`        | VPC ID where cluster resources will be created         | `string`       | —           | yes      |
| `subnet_ids`    | List of subnet IDs for the ASG and ALB                 | `list(string)` | —           | yes      |
| `min_size`      | Minimum number of EC2 instances in the ASG              | `number`       | —           | yes      |
| `max_size`      | Maximum number of EC2 instances in the ASG              | `number`       | —           | yes      |
| `instance_type` | EC2 instance type for the cluster                       | `string`       | `"t2.micro"`| no       |
| `server_port`   | Port the server uses for HTTP                            | `number`       | `8080`      | no       |

## Outputs

| Name                          | Description                                                             |
|-------------------------------|---------------------------------------------------------------------------|
| `alb_dns_name`                | The domain name of the load balancer                                     |
| `asg_name`                    | The name of the Auto Scaling Group                                       |
| `instance_security_group_id`  | Security group ID attached to cluster instances, for adding extra rules from the calling configuration |

## Known limitations / gotchas

- The instance security group intentionally has no inline `ingress`/`egress`
  blocks. All rules are managed as separate `aws_security_group_rule`
  resources so that calling configurations can attach additional rules
  (e.g. SSH from a specific IP range) to `instance_security_group_id`
  without modifying this module.
- The startup script (`user-data.sh`) is loaded via `path.module`, not a
  plain relative path, so it resolves correctly regardless of which
  root configuration calls this module.
- This module does not create a VPC or subnets. `vpc_id` and `subnet_ids`
  must be supplied by the caller.
- The ALB listener's default action returns a static 404 for any path not
  matched by a listener rule; this module does not configure HTTPS/TLS.