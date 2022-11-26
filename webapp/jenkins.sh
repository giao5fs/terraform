#!/bin/bash
echo "Start setting up....~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~>>>"
sudo yum install wget -y
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo 
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key 
sudo yum upgrade -y
sudo amazon-linux-extras install java-openjdk11 -y
java -version 
sudo yum install jenkins -y
sudo systemctl daemon-reload 
sudo systemctl enable jenkins 
sudo systemctl start jenkins
sudo service jenkins status
sudo yum install git -y
sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
sudo yum install dotnet-sdk-6.0 -y
sudo yum install httpd -y
sudo service httpd start

echo "Middle stage of setting up....~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~>>>"

cat >> temp.config<<EOF
<VirtualHost *:80>
    ProxyPreserveHost On
    ProxyPass / http://localhost:8080/
    ProxyPassReverse / http://localhost:8080/
    ServerName localhost
</VirtualHost>
EOF

sudo rm -Rf /etc/httpd/conf.d/welcome.conf
sudo sed 'w /etc/httpd/conf.d/jenkins.conf' temp.config

sudo httpd -t
sudo service httpd start
sudo service httpd status
echo "Completed~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~>>>"


