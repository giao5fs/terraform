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
  region = "us-east-1"
}

resource "aws_vpc" "demoaspnetcore_vpc" {
  cidr_block = "172.16.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "demoaspnetcore_vpc"
  }
}

resource "aws_subnet" "demoaspnetcore_subnet_private" {
  vpc_id            = aws_vpc.demoaspnetcore_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "demoaspnetcore_subnet_private"
  }
}

resource "aws_subnet" "demoaspnetcore_subnet_public1" {
  vpc_id            = aws_vpc.demoaspnetcore_vpc.id
  cidr_block        = "172.16.20.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "demoaspnetcore_subnet_public1"
  }
}

resource "aws_subnet" "demoaspnetcore_subnet_public2" {
  vpc_id            = aws_vpc.demoaspnetcore_vpc.id
  cidr_block        = "172.16.30.0/24"
  availability_zone = "us-east-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "demoaspnetcore_subnet_public2"
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

resource "aws_route_table_association" "demoaspnetcore_subnet_public1_ass" {
    subnet_id = aws_subnet.demoaspnetcore_subnet_public1.id
    route_table_id = aws_route_table.demoaspnetcore_routetable_public.id
}

resource "aws_route_table_association" "demoaspnetcore_subnet_public2_ass" {
    subnet_id = aws_subnet.demoaspnetcore_subnet_public2.id
    route_table_id = aws_route_table.demoaspnetcore_routetable_public.id
}

resource "aws_security_group" "webserverInstance-sg" {
    name = "webserverInstance-sg"
    ingress {
        from_port = 5000
        to_port = 5000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = aws_vpc.demoaspnetcore_vpc.id
}


resource "aws_security_group" "jenkinsInstance-sg" {
    name = "jenkinsInstance-sg"
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = aws_vpc.demoaspnetcore_vpc.id
}

resource "aws_instance" "webserver1" {
  ami             = "ami-0b0dcb5067f052a63" # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
  instance_type   = "t2.micro"
  subnet_id = aws_subnet.demoaspnetcore_subnet_private.id
  security_groups = [aws_security_group.webserverInstance-sg.id]
  tags = {
    Name = "webserver1"
  }
  user_data       = <<-EOF
              #!/bin/bash
              echo "Hello, World 1" > index.html
              python3 -m http.server 5000 &
              EOF
}

resource "aws_instance" "webserver2" {
  ami             = "ami-0b0dcb5067f052a63" # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
  instance_type   = "t2.micro"
  subnet_id = aws_subnet.demoaspnetcore_subnet_private.id
  security_groups = [aws_security_group.webserverInstance-sg.id]
  tags = {
    Name = "webserver2"
  }
  user_data       = <<-EOF
              #!/bin/bash
              echo "Hello, World 2" > index.html
              python3 -m http.server 5000 &
              EOF
}

resource "aws_instance" "jenkinsServer" {
  ami             = "ami-0b0dcb5067f052a63" # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
  instance_type   = "t2.micro"
  key_name = "pcKP"
  subnet_id = aws_subnet.demoaspnetcore_subnet_public1.id
  security_groups = [aws_security_group.jenkinsInstance-sg.id]
  associate_public_ip_address =  true
  tags = {
    Name = "jenkinsServer"
  }
  user_data       = <<-EOF
              #!/bin/bash
              echo "Hello, World from Jenkins" > index.html
              python3 -m http.server 8080 &
              EOF
}

resource "aws_s3_bucket" "bucket" {
  bucket        = "mime-devops-directive-web-app-data"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_crypto_conf" {
  bucket        = aws_s3_bucket.bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_lb_target_group" "demoaspnet-tg" {
  name     = "demoaspnet-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.demoaspnetcore_vpc.id

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

resource "aws_lb_target_group_attachment" "webserver1-att" {
  target_group_arn = aws_lb_target_group.demoaspnet-tg.arn
  target_id        = aws_instance.webserver1.id
  port             = 5000
}

resource "aws_lb_target_group_attachment" "webserver2-att" {
  target_group_arn = aws_lb_target_group.demoaspnet-tg.arn
  target_id        = aws_instance.webserver2.id
  port             = 5000
}

resource "aws_lb_listener_rule" "webserver-lsn" {
  listener_arn = aws_lb_listener.demoaspnetcore-http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demoaspnet-tg.arn
  }
}


resource "aws_security_group" "demoaspnetcore-alb-sg" {
  ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
  egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  name = "demoaspnetcore-alb-sg"
  vpc_id = aws_vpc.demoaspnetcore_vpc.id
    
}

resource "aws_lb" "demoaspnetcore-load_balancer" {
  name               = "web-app-lb"
  load_balancer_type = "application"
  subnet_mapping {
    subnet_id     = aws_subnet.demoaspnetcore_subnet_public1.id
  }

  subnet_mapping {
    subnet_id     = aws_subnet.demoaspnetcore_subnet_public2.id
  }

  subnet_mapping {
    subnet_id     = aws_subnet.demoaspnetcore_subnet_private.id
  }
  security_groups    = [aws_security_group.demoaspnetcore-alb-sg.id]
}

resource "aws_lb_listener" "demoaspnetcore-http" {
  load_balancer_arn = aws_lb.demoaspnetcore-load_balancer.arn

  port = 80

  protocol = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}