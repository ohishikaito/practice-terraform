provider "aws" {
  region = "ap-northeast-1"
}

variable "example_instance_type" {
  default = "t2.micro"
}

module "web_server" {
  source = "./http_server"
  # インスタンスタイプの指定をしない t3.mircoで
  instance_type = "t2.micro"
}

# publicDNSとは
# output "public_dns" {
#   value = module.web_server.public_dns
# }