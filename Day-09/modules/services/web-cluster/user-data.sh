#!/bin/bash
echo "Hello from ${cluster_name}" > index.html
nohup busybox httpd -f -p ${server_port} &