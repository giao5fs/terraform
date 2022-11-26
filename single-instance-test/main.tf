terraform {
  # Assumes s3 bucket and dynamo DB table already set up
  # See /code/03-basics/aws-backend
  backend "s3" {
    bucket         = "mime-devops-directive-tf-state"
    key            = "03-basics/web-app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "demoaspnetcore_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "demoaspnetcore_vpc"
  }
}

resource "aws_subnet" "demoaspnetcore_subnet_public" {
  vpc_id                  = aws_vpc.demoaspnetcore_vpc.id
  cidr_block              = "172.16.10.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "demoaspnetcore_subnet_public"
  }
}


resource "aws_internet_gateway" "demoaspnetcore-igw" {
  vpc_id = aws_vpc.demoaspnetcore_vpc.id
  tags = {
    Name = "demoaspnetcore-igw"
  }
}

resource "aws_route_table" "demoaspnetcore_routetable_public" {
  vpc_id = aws_vpc.demoaspnetcore_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demoaspnetcore-igw.id
  }
  tags = {
    Name = "demoaspnetcore_routetable_public"
  }
}
resource "aws_main_route_table_association" "demoaspnetcore_subnet_public_ass" {
  vpc_id = aws_vpc.demoaspnetcore_vpc.id
  route_table_id = aws_route_table.demoaspnetcore_routetable_public.id
}

resource "aws_security_group" "webserverInstance-sg" {
  name = "webserverInstance-sg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.demoaspnetcore_vpc.id
}

resource "aws_instance" "webserver1" {
  ami             = var.ami
  instance_type   = var.instance_type
  key_name        = var.key_name
  subnet_id       = aws_subnet.demoaspnetcore_subnet_public.id
  security_groups = [aws_security_group.webserverInstance-sg.id]
  tags = {
    Name = "webserver1"
  }
  user_data = var.user_data_webserver1

  connection {
    type        = "ssh"
    user        = local.ssh_user
    private_key = file(local.private_key_path)
    host        = aws_instance.webserver1.public_ip
  }
  
  provisioner "file" {
    source      = "testserver.sh"
    destination = "/tmp/testserver.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/testserver.sh",
      "/tmp/testserver.sh args",
    ]
  }
}

output "webserver1_ip" {
  value = aws_instance.webserver1.public_ip
}
