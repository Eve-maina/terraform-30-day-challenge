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

resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow HTTP traffic on the configured server port"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
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

resource "aws_instance" "web_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    echo "<h1>Day 4 - Configurable Web Server</h1>" > /var/www/html/index.html
    sed -i "s/Listen 80/Listen ${var.server_port}/" /etc/httpd/conf/httpd.conf
    systemctl start httpd
    systemctl enable httpd
  EOF

  tags = {
    Name = "day04-configurable-web-server"
  }
}

output "public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "The public IP of the web server"
}

output "url" {
  value       = "http://${aws_instance.web_server.public_ip}:${var.server_port}"
  description = "URL to reach the web server"
}
