#!/bin/bash

dnf update -y

dnf install -y httpd

systemctl enable httpd
systemctl start httpd

cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>AWS Terraform Project</title>
</head>
<body>
    <h1>AWS Infrastructure Automation using Terraform</h1>
    <p>Web application deployed successfully on Amazon EC2.</p>
    <p>Infrastructure provisioned using Terraform.</p>
    <p>Environment: Dev</p>
</body>
</html>
EOF