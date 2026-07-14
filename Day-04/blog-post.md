# Deploying a Highly Available Web App on AWS Using Terraform

*Day 4 of the 30-Day Terraform Challenge, a walkthrough*

Day 3 ended with a real, working web server on AWS. A genuine EC2 instance, provisioned entirely through code, serving up a page in a browser. It felt like a milestone, and it was. But hiding inside that `main.tf` was a small, quiet problem: everything about that server was welded in place. The AMI ID, the instance type, the port, all typed directly into the resource block as literal text. Today fixes that, then goes further and turns one server into a cluster that can survive one dying. Follow along in order. Each step tells you what to run and what's actually happening underneath it.

## Step 1: Look at what you're starting with

Open up your Day 3 `main.tf`. Find the AMI ID, the instance type, and the port. They're typed straight into the resource block, literal text. That's the thing we're about to fix.

## Step 2: Pull the hardcoded values into variables

Create a `variables.tf` file and declare a box for each value that used to be hardcoded:

```terraform
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}
```

This doesn't create anything by itself. It's a labeled slot, a box with a name, a type, and a default value sitting inside until someone says otherwise. Once declared, `var.server_port` can be dropped anywhere in your configuration:

```terraform
resource "aws_security_group" "web_sg" {
  ingress {
    from_port = var.server_port
    to_port   = var.server_port
  }
}
```

The security group's open port and the actual port Apache listens on now both trace back to this same variable, so they can never quietly drift apart. That's the DRY principle, Don't Repeat Yourself, in practice. Not an abstract rule, but a concrete guarantee: change one number in one place, and the truth changes everywhere it matters. Picture a team of five engineers all hardcoding `t2.micro` into their own copies of a resource block. The day someone needs to bump one environment to a bigger instance, they're hunting through files hoping they found every occurrence. With variables, they change a default once, and every environment that didn't override it inherits the update.

Do the same for `instance_type`, `ami_id`, and `aws_region`, each pulled into its own `variable` block with a sensible default.

## Step 3: A quick detour on naming, before the code gets confusing

You're about to write resource blocks with names stacked on names, so it's worth pausing here. Here's the general structure of how naming works in Terraform:

```terraform
resource "aws_security_group" "web_sg" {
  name = "web-server-sg"
}
```

- **Resource type** (e.g. `aws_security_group`): what kind of thing this is, fixed vocabulary defined by the AWS provider, never something you make up.
- **Local nickname** (e.g. `web_sg`): what you call it inside your own Terraform files, used to reference it elsewhere like `aws_security_group.web_sg.id`. AWS never sees this word.
- **Name argument** (e.g. `"web-server-sg"`): what AWS itself calls it, the only one of the three that actually gets sent to AWS and shows up in the console.

Not every block follows this two-label pattern. `provider "aws" { }` only gets one label, because you normally only have one AWS provider per config. `terraform { }` gets zero, since there's only ever one per file. Keep an eye out for two more patterns as you read: `var.something` always means "go read the variable box named something," and `resource_type.nickname.attribute`, like `aws_vpc.main.id`, always means "go grab an attribute off a resource already defined in this file."

## Step 4: Give the server its own VPC

Instead of letting the instance land in whatever default VPC AWS hands you, build one on purpose:

```terraform
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}
```

Four resources, four jobs. The VPC draws the property line (`10.0.0.0/16`, 65,536 addresses, more than enough for a lab). The subnet is the actual plot of land inside it. The internet gateway is the front gate connecting that property to the outside world. The route table is the signpost telling traffic which way leads to that gate. Skip any one of these and the house exists but has no door: an instance could boot up perfectly healthy and still be completely unreachable.

## Step 5: Initialize, plan, and apply the configurable server

From inside `configurable-server/`, run these three commands in order:

```bash
terraform init
```

This reads every `.tf` file in the folder, sees you need the AWS provider, and downloads it. It creates a `.terraform/` folder to hold that download and a `.terraform.lock.hcl` file recording exactly which version got installed.

```bash
terraform plan
```

A dry run. Terraform tells you what it would create, without touching anything yet. Read through it and confirm nothing unexpected shows up.

```bash
terraform apply
```

Type `yes` when prompted. This is the command that actually talks to AWS and builds the VPC, subnet, security group, and instance. Once it finishes, grab the output:

```bash
terraform output
```

Visit the URL it gives you (`http://<public_ip>:8080`) and confirm the page loads.

## Step 6: Destroy it before moving on

```bash
terraform destroy
```

Type `yes` to confirm. Do this now, before starting the cluster below, so you're not paying for two sets of infrastructure at once. Get in the habit of running `destroy` the moment you're done testing anything in this challenge. Leaving lab infrastructure running is the single easiest way to get a surprise AWS bill.

## Step 7: Build the cluster, one piece at a time

A single server, no matter how well configured, has exactly one way to fail: catastrophically. The fix isn't a bigger server. It's more servers, managed by machinery that doesn't need a human awake at 3am to notice something died. Four resources make this work, and each one only needs to understand the piece directly next to it.

First, the launch template, a recipe, not a meal:

```terraform
resource "aws_launch_template" "web_server" {
  image_id      = var.ami_id
  instance_type = var.instance_type
  user_data     = base64encode(<<-EOF
    #!/bin/bash
    yum install -y httpd
    echo "<h1>Day 4 - Clustered Web Server</h1>" > /var/www/html/index.html
    systemctl start httpd
  EOF
  )
}
```

Applying this block on its own creates zero running servers. It just describes what an instance should look like, waiting for something else to actually build one.

Next, the Auto Scaling Group, the one who keeps building:

```terraform
resource "aws_autoscaling_group" "web_asg" {
  min_size          = 2
  max_size          = 5
  health_check_type = "ELB"
  target_group_arns = [aws_lb_target_group.asg_tg.arn]

  launch_template {
    id = aws_launch_template.web_server.id
  }
}
```

Its entire job is maintaining a headcount, never fewer than 2 servers, never more than 5. When it needs a new one, it doesn't know anything about AMIs or Apache. It just follows the recipe and gets an identical server every time. When one dies or fails a health check, it removes it from the count and builds a replacement, with nobody paged and nobody clicking anything in a console at 3am.

Then the target group, a live roster, not a guest list written once:

```terraform
resource "aws_lb_target_group" "asg_tg" {
  port     = var.server_port
  protocol = "HTTP"
  health_check {
    path                = "/"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
```

Every fifteen seconds it checks in on every instance registered with it and asks whether it's still responding. It's not just holding a static list of instance IDs, it's actively grading each one's health in real time. That's why the ASG above was told `health_check_type = "ELB"` instead of trusting AWS's bare-bones "is the VM technically powered on" check. An instance can be fully booted and still be useless if Apache crashed inside it, and only the target group's opinion catches that.

Finally, the Application Load Balancer, the only door the public ever knocks on:

```terraform
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port               = 80
  default_action {
    target_group_arn = aws_lb_target_group.asg_tg.arn
  }
}
```

Nobody on the internet ever learns any instance's address. They only know one DNS name, the ALB's, and every request in both directions gets proxied through it. The ALB asks the target group who's healthy right now, forwards the request to one of them, waits for the response, and hands that response back to the browser as if it produced it itself.

## Step 8: Look at the security groups that lock it down

Two independent security groups make the whole thing safe:

```terraform
resource "aws_security_group" "alb_sg" {
  ingress {
    from_port   = var.alb_port
    to_port     = var.alb_port
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance_sg" {
  ingress {
    from_port       = var.server_port
    to_port         = var.server_port
    security_groups = [aws_security_group.alb_sg.id]
  }
}
```

`alb_sg` is the only one of the two that mentions `0.0.0.0/0`, meaning it's the only thing in this whole setup allowed to accept traffic from literally anywhere on the internet. `instance_sg` never mentions the internet at all. Its `ingress` rule points at `security_groups = [aws_security_group.alb_sg.id]`, which tells AWS "only accept traffic that's coming from something already inside `alb_sg`," not any IP address, not any CIDR range, just that one specific security group.

That single line is the whole reason instances stay unreachable directly. Even though the instances technically have public IPs in this lab (kept simple on purpose; production setups usually hide them in private subnets with none at all), an IP address alone doesn't get you in. AWS checks the security group rule first, sees the request isn't coming from `alb_sg`, and drops it before it ever reaches Apache.

## Step 9: Initialize, plan, and apply the cluster

From inside `clustered-server/`, same three commands:

```bash
terraform init
terraform plan
terraform apply
```

Confirm with `yes`. This one takes longer than the single-instance apply, because the ASG has to launch instances and wait for them to pass health checks before Terraform considers the apply finished. Give it a couple of minutes.

```bash
terraform output alb_dns_name
```

Copy that DNS name and paste it into your browser as plain `http://`, not `https://`, and without adding a port number. Confirm the page loads.

## Step 10: Trace a request end to end

Worth doing once by hand, because this is the part that makes the whole architecture click:

1. Your browser resolves the ALB's DNS name, never an instance's IP. It has no idea instances even exist.
2. The request lands on the ALB, inside `alb_sg`, which only allows inbound HTTP from the internet.
3. The ALB asks the target group which instances currently pass health checks, and forwards your request to one.
4. That instance, locked behind `instance_sg`, processes the request and hands a response back to the ALB.
5. The ALB relays that response to your browser. You were never, at any point, talking to the instance directly.

## Step 11: Two gotchas to watch for

If `terraform apply` on the cluster fails with `The specified instance type is not eligible for Free Tier`, don't panic and don't assume your code is wrong. AWS changed which instance size counts as free tier for accounts created after mid-2022, and `t2.micro`, the type most tutorials assume, might not be what your account gets. Run `aws ec2 describe-instance-types --filters "Name=free-tier-eligible,Values=true"` to see what your account actually qualifies for, then update `instance_type`'s default and re-apply.

If your editor suddenly shows bizarre parse errors, "Invalid character" or "no declaration found" on lines that look fine, check whether the file itself got cut short before you go hunting for a logic bug. A file that ends mid-word, missing a closing brace it should have, is a sign of a bad save or sync, not bad Terraform.

## Step 12: Destroy everything when you're done

```bash
terraform destroy
```

Confirm with `yes`. Do this for the cluster the same way you did for the configurable server. Nothing here needs to stay running after you've confirmed it works, and every hour it stays up is an hour it could be costing you. Capture your `alb_dns_name` and any screenshots you need before you run this command, since it's the last chance to see the live version.

## Configurable vs. clustered, the line that actually matters

Day 3 and the configurable server are, underneath the variables, the exact same architecture: one instance, one security group, one point of failure dressed up in nicer clothes. The cluster is a different shape of thing entirely, not a bigger server, but a system that assumes failure is normal rather than an emergency. An instance dying in the clustered setup is a Tuesday. The ASG replaces it and the target group routes around the gap before anyone outside the system notices. An instance dying in the single-server setup is an outage. That's the actual boundary between a demo and something that could survive real traffic.

---

**#30DayTerraformChallenge #TerraformChallenge #Terraform #AWS #HighAvailability #IaC #AWSUserGroupKenya #EveOps**
