#!/bin/bash
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "Hello from ${cluster_name}" > /var/www/html/index.html