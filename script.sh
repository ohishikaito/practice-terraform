#!/bin/bash
yum install -y httpd
systemctl start httpd.service

# 練習用に書いたけど使ってない！ file("./script.sh") で呼べる