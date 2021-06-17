variable "name" {}
variable "policy" {}
variable "identifer" {}

resource "aws_iam_role" "default" {
  name = var.name
  # 11行目のやつを読み込んでるっぽい！
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifers = [var.identifer]
    }
  }
}

resource "aws_iam_policy" "default" {
  name = var.name
  policy = var.policy
}

resource "aws_iam_role_policy_attachment" "default" {
  role = aws_iam_role.default.arn
  policy_arn = aws_iam_policy.default.arn
}

output "iam_role_arn" {
  value = aws_iam_role.default.arn
}

output "iam_role_name" {
  value = aws_iam_role.default.name
}