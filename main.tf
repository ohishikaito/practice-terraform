provider "aws" {
  region = "ap-northeast-1"
}

variable "example_instance_type" {
  default = "t2.micro"
}

# locals {
#   example_instance_type = "t2.micro"
# }

resource "aws_security_group" "example_ec2" {
  name = "example-ec2"

  ingress = [ {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = null
    from_port = 80
    ipv6_cidr_blocks = null
    prefix_list_ids = null
    protocol = "tcp"
    security_groups = null
    self = false
    to_port = 80
  } ]

  egress = [ {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = null
    from_port = 0
    ipv6_cidr_blocks = null
    prefix_list_ids = null
    protocol = "-1"
    security_groups = null
    self = false
    to_port = 0
  } ]
}

resource "aws_instance" "example" {
  ami = "ami-0c3fd0f5d33134a76"
  instance_type = var.example_instance_type
  # vpc_security_group_ids = [ "aws_security_group.example_ec2.id" ]
  vpc_security_group_ids = [ aws_security_group.example_ec2.id ]
  user_data = <<EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd.service
EOF
}

# publicDNSとは
output "example_instance_id" {
  value = aws_instance.example.public_dns
}