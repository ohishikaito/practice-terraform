provider "aws" {
  region = "ap-northeast-1"
}

data "aws_iam_policy_document" "allow_describe_regions" {
  statement {
    effect = "Allow"
    actions = ["ec2:DescribeRegions"]
    resources = [ "*" ]
  }
}

module "describe_regions_for_ec2" {
  source = "./iam_role"
  name = "describe-regions-for-ec2"
  identifier = "ec2.amazonaws.com"
  policy = data.aws_iam_policy_document.allow_describe_regions.json
}

resource "aws_s3_bucket" "private" {
  bucket = "private-pragmatic-terraform-ohishikaito20210618"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "private" {
  bucket = aws_s3_bucket.private.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "public" {
  bucket = "public-pragmatic-terraform-ohishikaito20210618"
  acl = "public-read"

  cors_rule {
    allowed_origins = ["https://example.com"]
    allowed_methods = ["GET"]
    allowed_headers = [ "*" ]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "alb_log" {
  bucket = "al-log-pragmatic-terraform-ohishikaito20210618"

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

data "aws_iam_policy_document" "alb_log" {
  statement {
    effect = "Allow"
    actions = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type = "AWS"
      identifiers = [ "504300096460" ]
    }
  }
}

resource "aws_s3_bucket" "force_destroy" {
  bucket = "force-destroy-pragmatic-terraform-ohishikaito20210618"
  force_destroy = true
}

resource "aws_ecs_cluster" "example" {
  name = "example"
}

# resource "aws_ecs_task_definition" "example" {
#   family = "example"
#   cpu = "256"
#   memory = "512"
#   network_mode = "awsvpc"
#   requires_compatibilities = [ "FARGATE" ]
#   container_definitions = file("./task_definitions.json")
#   execution_role_arn = module.ecs_task_execution_role.iam_role_arn
# }

resource "aws_ecs_service" "example" {
  name = "example"
  cluster = aws_ecs_cluster.example.arn
  task_definition = aws_ecs_task_definition.example.arn
  desired_count = 2
  launch_type = "FARGATE"
  platform_version = "1.3.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups = [module.nginx_sg.security_group_id]

    subnets = [
      aws_subnet.private_0.id,
      aws_subnet.private_1.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.example.arn
    container_name = "example"
    container_port = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

module "nginx_sg" {
  source = "./security_group"
  name = "nginx-sg"
  vpc_id = aws_vpc.example.id
  port = 80
  cidr_blocks = [aws_vpc.example.cidr_block]
}

resource "aws_cloudwatch_log_group" "for_ecs" {
  name = "/ecs/example"
  retention_in_days = 180
}

data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_execution" {
  source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy

  statement {
    effect = "Allow"
    actions = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }
}

module "ecs_task_execution_role" {
  source = "./iam_role"
  name = "ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy = data.aws_iam_policy_document.ecs_task_execution.json
}

resource "aws_ecs_task_definition" "example" {
  family = "example"
  cpu = "256"
  memory = "512"
  network_mode = "awsvpc"
  requires_compatibilities = [ "FARGATE" ]
  container_definitions = file("./container_definitions.json")
  execution_role_arn = module.ecs_task_execution_role.iam_role_arn
}

# aws logs filter-log-events --log-group-name /ecs/example
# コマンド叩いても、↓が出る。
# An error occurred (ResourceNotFoundException) when calling the FilterLogEvents operation: The specified log group does not exist.
# 先にロググループ生成してapplyしようとしたら、applyで落ちる
# 旧 aws_ecs_task_definition.example をコメントアウトしたらapplyできてコマンド反応した！
# レスポンスないけど笑

# 1354