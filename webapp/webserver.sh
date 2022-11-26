#!/bin/bash
echo "Start setting up....~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~>>>"
sudo yum update -y
sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
sudo yum install aspnetcore-runtime-6.0 -y
sudo yum install firewalld -y
sudo service firewalld start
sudo service firewalld status
sudo firewall-cmd --zone=public --add-port=5000/tcp --permanent
sudo firewall-cmd --add-port=80/tcp --permanent  
sudo firewall-cmd --add-port=443/tcp --permanent  
sudo firewall-cmd --reload  
sudo firewall-cmd --list-all

echo "Middle stage of setting up....~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~>>>"
#create user jenkins
sudo useradd jenkins
sudo usermod -aG wheel jenkins

#grant root permission for these users
sudo sed -i '101 a ec2-user  ALL=(ALL)       ALL' /etc/sudoers
sudo sed -i '101 a jenkins  ALL=(ALL)       ALL' /etc/sudoers

#to replace giao5fs to giaonx 
sudo sed -i --follow-symlinks 's/^%wheel/#%wheel/' /etc/sudoers
sudo sed -i '110 a %wheel ALL=(ALL)       NOPASSWD: ALL' /etc/sudoers

cat >> temp.config<<EOF
[Unit] 
Description= DemoDeployDotnetCore
[Service] 
WorkingDirectory=/home/jenkins/DemoDeployDotnetCore
ExecStart=/usr/bin/dotnet /home/jenkins/DemoDeployDotnetCore/DemoDeployDotnetCore.dll 
Restart=always  
RestartSec=10 
KillSignal=SIGINT 
SyslogIdentifier=DemoDeployDotnetCore
User=jenkins
Environment=ASPNETCORE_ENVIRONMENT=Production 
[Install] 
WantedBy=multi-user.target
EOF

sudo sed 'w /etc/systemd/system/webapp.service' temp.config

sudo systemctl daemon-reload
# sudo systemctl restart webapp
# sudo systemctl status webapp

echo "Completed~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~>>>"
