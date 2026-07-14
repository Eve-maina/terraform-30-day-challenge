terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------
# Security Groups
# ---------------------------------------------------------------------------

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP in from the internet, all traffic out"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = var.alb_port
    to_port     = var.alb_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "instance-sg"
  description = "Allow HTTP from the ALB only, all traffic out"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = var.server_port
    to_port         = var.server_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------------------------
# Launch Template + Auto Scaling Group
# ---------------------------------------------------------------------------

resource "aws_launch_template" "web_server" {
  name_prefix   = "day04-web-server-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    echo "<h1>Day 4 - Clustered Web Server ($(hostname -f))</h1>" > /var/www/html/index.html
    sed -i "s/Listen 80/Listen ${var.server_port}/" /etc/httpd/conf/httpd.conf
    systemctl start httpd
    systemctl enable httpd
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "day04-clustered-web-server"
    }
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name                = "day04-web-asg"
  vpc_zone_identifier = aws_subnet.public[*].id

  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.min_size
  health_check_type   = "ELB"
  target_group_arns   = [aws_lb_target_group.asg_tg.arn]

  launch_template {
    id      = aws_launch_template.web_server.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "day04-web-asg-instance"
    propagate_at_launch = true
  }
}

# ---------------------------------------------------------------------------
# Application Load Balancer
# ---------------------------------------------------------------------------

resource "aws_lb" "web_alb" {
  name               = "day04-web-alb"
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "asg_tg" {
  name     = "day04-web-asg-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = var.alb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg_tg.arn
  }
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "alb_dns_name" {
  value       = aws_lb.web_alb.dns_name
  description = "DNS name of the load balancer — hit this in a browser"
}
