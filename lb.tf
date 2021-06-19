output "alb_dns_name" {
  value = aws_lb.example.dns_name
}

module "http_sg" {
  source = "./security_group"
  name = "http-sg"
  vpc_id = aws_vpc.example.id
  port = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source = "./security_group"
  name = "https-sg"
  vpc_id = aws_vpc.example.id
  port = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
  source = "./security_group"
  name = "http-redirect-sg"
  vpc_id = aws_vpc.example.id
  port = 8080
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは「HTTP」です"
      status_code = "200"
    }
  }
}

resource "aws_lb" "example" {
  name = "example"
  load_balancer_type = "application"
  internal = false
  idle_timeout = 60
  enable_deletion_protection = true

  subnets = [
    aws_subnet.public_0.id,
    aws_subnet.public_1.id,
  ]

  # s3の権限エラー出るからコメントアウト
  # access_logs {
  #   bucket = aws_s3_bucket.alb_log.id
  #   enabled = true
  # }

  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id,
  ]
}

# data "aws_route53_zone" "example" {
#   name = "example.com"
# }

# resource "aws_route53_zone" "test_example" {
#   name = "test.example.com"
# }

# resource "aws_route53_record" "example" {
#   zone_id = data.aws_route53_zone.example.zone_id
#   name = data.aws_route53_zone.example.name
#   type = "A"

#   alias {
#     name = aws_lb.example.dns_name
#   }
# }
