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
  # 削除しないコマンドらしい。こいつがあるから消せない説？
  # enable_deletion_protection = true

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

# mynote.worldは必須
data "aws_route53_zone" "example" {
  # zone_id = "Z09170502X22Y1VY1UIK5"
  name = "mynote.world"
}

# 呼ばれてない
resource "aws_route53_zone" "test_example" {
  name = "test.mynote.world"
}

resource "aws_route53_record" "example" {
  zone_id = data.aws_route53_zone.example.zone_id
  name = data.aws_route53_zone.example.name
  type = "A"

  alias {
    name = aws_lb.example.dns_name
    zone_id = aws_lb.example.zone_id
    evaluate_target_health = true
  }
}

output "domain_name" {
  value = aws_route53_record.example.name
}
# ここでapplyするらしいけど、route53登録してないから動かないんじゃ？
# mynote.world使うように変えた！
# outputで出されたnameにHTTPアクセスすればokらしい

# Error: multiple Route53Zone found please use vpc_id option to filter

#   on lb.tf line 71, in data "aws_route53_zone" "example":
#   71: data "aws_route53_zone" "example" {
# って言われんのうぜええええ　起動すらできない➡️レコード消してやったぜ！糞が死ね
# レコード消しちゃったせいで色々めんどいから、全部削除する！
# 次は起動＆削除ができるか？➡️レコード名変えよう。かぶってそう
# ➡️mynote.worldにしないと↓のerrでる
# Error: no matching Route53Zone found
#   on lb.tf line 71, in data "aws_route53_zone" "example":
#   71: data "aws_route53_zone" "example" {
# もう1回ACMを設定してみよう！
# ➡️apply2回する➡️検証保留中になってるのが原因っぽい！
# terraformからACMだとめんどくさいらしいので、予め作ったやつを読み込ませる

# resource "aws_acm_certificate" "example" {
  # domain_name = aws_route53_record.example.name
  # subject_alternative_names = []
  # validation_method = "DNS"

  # lifecycle {
  #   create_before_destroy = true
  # }
# }
data "aws_acm_certificate" "exmaple" {
  domain = "mynote.world"
  statuses = ["ISSUED"]
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.example.arn
  port = "443"
  protocol = "HTTPS"
  # certificate_arn = aws_acm_certificate.example.arn
  certificate_arn = data.aws_acm_certificate.exmaple.arn
  ssl_policy = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは！！！HTTTPS！！！です！！！"
      status_code = "200"
    }
  }
}

resource "aws_lb_listener" "redirect_http_to_https" {
  load_balancer_arn = aws_lb.example.arn
  port = "8080"
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "example" {
  name = "example"
  # ここはECS EC2タイプ使うときはinstanceになりそう！
  target_type = "ip"
  vpc_id = aws_vpc.example.id
  port = 80
  protocol = "HTTP"
  deregistration_delay = 300

  health_check {
    path = "/"
    healthy_threshold = 5
    unhealthy_threshold = 2
    timeout = 5
    interval = 30
    matcher = 200
    port = "traffic-port"
    protocol = "HTTP"
  }

  depends_on = [
    aws_lb.example
  ]
}

resource "aws_lb_listener_rule" "example" {
  listener_arn = aws_lb_listener.https.arn
  priority = 100

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }

  # conditionは必須、ないとerr出る
  condition {
    path_pattern {
      values = [ "/*" ]
    }
  }
}