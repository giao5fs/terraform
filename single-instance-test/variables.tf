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

            EOF
}