#!/bin/bash
yum install -y httpd
systemctl start httpd
systemctl enable httpd
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>${cluster_name}</title>
  <style>
    body {
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100vh;
      margin: 0;
      font-family: Arial, Helvetica, sans-serif;
      background-color: #1a1a2e;
      color: #f0f0f0;
    }
    .card {
      text-align: center;
      padding: 2rem 3rem;
      border-radius: 12px;
      background-color: #16213e;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
    }
    h1 {
      margin: 0 0 0.5rem;
      font-size: 2rem;
    }
    p {
      margin: 0;
      color: #9ca3af;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>Hello from the cloud</h1>
    <p>Served by ${cluster_name}</p>
  </div>
</body>
</html>
EOF