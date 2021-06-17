variable "instance_type" {}

resource "aws_instance" "default" {
  ami = "ami-0c3fd0f5d33134a76"
  vpc_security_group_ids = [ aws_security_group.default.id ]
  # 本だとexample_ない。moduleを参照してるってことか！
  # instance_type = var.example_instance_type
  instance_type = var.instance_type
  # 本だとEOFだけどfile使ってみたかった！
  # user_data = file("../script.sh")
  user_data = <<EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd.service
EOF
}

resource "aws_security_group" "default" {
  name = "ec2"

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