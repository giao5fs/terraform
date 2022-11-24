variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "172.16.0.0/16"
}

variable "ami" {
  default = "ami-0b0dcb5067f052a63"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "pcKP"
}

variable "user_data_webserver1" {
  default = <<-EOF
            #!/bin/bash
            sudo su -
            yum update -y
            yum install nginx
            systemctl enable nginx
            systemctl start nginx
            sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
            sudo yum install aspnetcore-runtime-3.1
            sudo yum install firewalld -y
            service firewalld start
            service firewall status
            firewall-cmd --zone=public --add-port=5000/tcp --permanent
            sudo firewall-cmd --add-port=80/tcp --permanent  
            sudo firewall-cmd --add-port=443/tcp --permanent  
            sudo firewall-cmd --reload  
            sudo firewall-cmd --list-all
            echo "123" | passwd --stdin root
            sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
            systemctl reload sshd
            EOF
}

variable "user_data_webserver2" {
  default = <<-EOF
            #!/bin/bash
            sudo su -
            yum update -y
            yum install nginx
            systemctl enable nginx
            systemctl start nginx
            sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
            sudo yum install aspnetcore-runtime-3.1
            sudo yum install firewalld -y
            service firewalld start
            service firewall status
            firewall-cmd --zone=public --add-port=5000/tcp --permanent
            sudo firewall-cmd --add-port=80/tcp --permanent  
            sudo firewall-cmd --add-port=443/tcp --permanent  
            sudo firewall-cmd --reload  
            sudo firewall-cmd --list-all
            echo "123" | passwd --stdin root
            sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
            systemctl reload sshd
            EOF
}

variable "user_data_jenkins" {
  default = <<-EOF
            #!/bin/bash
            yum install wget 
            sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo 
            sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key 
            sudo yum upgrade 
            sudo amazon-linux-extras install java-openjdk11 
            java -version 
            sudo yum install jenkins  
            sudo systemctl daemon-reload 
            yum install git
            systemctl enable jenkins 
            systemctl start jenkins
            service jenkins status
            EOF
}
